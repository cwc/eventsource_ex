defmodule EventsourceEx do
  use Application
  require Logger

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(EventsourceEx.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EventsourceEx.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @spec new(String.t, Keyword.t) :: {:ok, pid}
  def new(url, opts \\ []) do
    start_link(url, opts)
  end

  def start_link(url, opts \\ []) do
    parent = opts[:stream_to] || self

    pid = spawn_link fn -> 
      HTTPoison.get!(url, [], stream_to: self, recv_timeout: :infinity)

      receive_loop(parent)
    end

    {:ok, pid}
  end

  defp receive_loop(parent, message \\ %EventsourceEx.Message{}, prev_chunk \\ nil) do
    receive do
      %{chunk: data} ->
        data = if prev_chunk, do: prev_chunk <> data, else: data

        if String.ends_with?(data, "\n") do
          data = String.split(data, "\n")

          message = parse_stream(data, parent, message)

          receive_loop(parent, message)
        else
          # Chunk didn't end with newline - assume data was cut and append next chunk
          receive_loop(parent, message, data)
        end

      %HTTPoison.AsyncEnd{} -> :ok # Terminate when request ends

      :stop -> :ok
      _ -> receive_loop(parent, message, prev_chunk)
    end
  end

  defp parse_stream(["" | data], parent, message) do
    if message.data, do: dispatch(parent, message)
    parse_stream(data, parent, %EventsourceEx.Message{})
  end
  defp parse_stream([line | data], parent, message) do
    message = parse(line, message)
    parse_stream(data, parent, message)
  end
  defp parse_stream([], _, message), do: message
  defp parse_stream(data, _, _), do: raise ArgumentError, message: "Unparseable data: #{data}"

  defp parse(raw_line, message) do
    case raw_line do
      ":" <> _ -> message
      line ->
        splits = String.split(line, ":", parts: 2)
        [field | rest] = splits
        value = Enum.join(rest, "") |> String.replace_prefix(" ", "") # Remove single leading space

        case field do
          "event" -> Map.put(message, :event, value)
          "data" ->
            data = message.data || ""
            Map.put(message, :data, data <> value <> "\n")
          "id" -> Map.put(message, :id, value)
          _ -> message
        end
    end
  end

  defp dispatch(parent, message) do
    message = Map.put(message, :data, message.data |> String.replace_suffix("\n", "")) # Remove single trailing \n from message.data if necessary
    |> Map.put(:dispatch_ts, DateTime.utc_now) # Add dispatch timestamp
   
    send(parent, message)
  end
end
