defmodule EventsourceEx do
  use GenServer
  require Logger

  @spec new(String.t(), Keyword.t()) :: {:ok, pid}
  def new(url, opts \\ []) do
    parent = opts[:stream_to] || self()

    opts =
      Keyword.put(opts, :stream_to, parent)
      |> Keyword.put(:url, url)

    GenServer.start_link(__MODULE__, opts, opts)
  end

  defp parse_options(opts) do
    method = opts[:method] || :get
    url = opts[:url]
    headers = opts[:headers] || []
    parent = opts[:stream_to]
    follow_redirect = opts[:follow_redirect]
    hackney_opts = opts[:hackney]
    ssl = opts[:ssl]
    adapter = opts[:adapter] || HTTPoison

    http_options = [
      stream_to: self(),
      ssl: ssl,
      follow_redirect: follow_redirect,
      hackney: hackney_opts,
      recv_timeout: :infinity
    ]

    {url, headers, parent, adapter, Enum.reject(http_options, fn {_, val} -> is_nil(val) end),
     method}
  end

  def init(opts \\ []) do
    {url, headers, parent, adapter, options, method} = parse_options(opts)
    Logger.debug(fn -> "starting stream with http options: #{inspect(options)}" end)

    if method == :post do
      body = Keyword.get(opts, :body, "")

      [url: url, body: body, headers: headers, options: options]

      adapter.post!(url, body, headers, options)
    else
      adapter.get!(url, headers, options)
    end

    {:ok, %{parent: parent, message: %EventsourceEx.Message{}, prev_chunk: nil}}
  end

  def handle_info(%{chunk: data}, %{parent: parent, message: message, prev_chunk: prev_chunk}) do
    data = if prev_chunk, do: prev_chunk <> data, else: data

    lines = String.split(data, ~r/^/m, trim: true)

    {prev_chunk, lines} =
      if not String.ends_with?(data, "\n") do
        List.pop_at(lines, -1)
      else
        {nil, lines}
      end

    message = parse_stream(lines, parent, message)

    {:noreply, %{parent: parent, message: message, prev_chunk: prev_chunk}}
  end

  def handle_info(%HTTPoison.AsyncEnd{}, state) do
    {:stop, :connection_terminated, state}
  end

  def handle_info(_msg, state) do
    # Ignore unhandled messages
    {:noreply, state}
  end

  defp parse_stream(["\n" | data], parent, message) do
    if message.data, do: dispatch(parent, message)
    parse_stream(data, parent, %EventsourceEx.Message{})
  end

  defp parse_stream([line | data], parent, message) do
    message = parse(line, message)
    parse_stream(data, parent, message)
  end

  defp parse_stream([], _, message), do: message

  defp parse(raw_line, message) do
    raw_line = String.trim_trailing(raw_line, "\n")

    case raw_line do
      ":" <> _ ->
        message

      line ->
        splits = String.split(line, ":", parts: 2)
        [field | rest] = splits
        # Remove single leading space
        value = Enum.join(rest, "") |> String.replace_prefix(" ", "")

        case field do
          "event" ->
            Map.put(message, :event, value)

          "data" ->
            data = message.data || ""
            Map.put(message, :data, data <> value <> "\n")

          "id" ->
            Map.put(message, :id, value)

          _ ->
            message
        end
    end
  end

  defp dispatch(parent, message) do
    # Remove single trailing \n from message.data if necessary
    message =
      Map.put(message, :data, message.data |> String.replace_suffix("\n", ""))
      # Add dispatch timestamp
      |> Map.put(:dispatch_ts, DateTime.utc_now())

    send(parent, message)
  end
end
