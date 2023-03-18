# EventsourceEx

An Elixir EventSource (Server-Sent Events) client

[![EventsourceEx on Hex](https://img.shields.io/hexpm/v/eventsource_ex?style=flat-square)](https://hex.pm/packages/eventsource_ex)

## Installation

  Add eventsource_ex to your list of dependencies in `mix.exs`:

        def deps do
          [{:eventsource_ex, "~> x.x.x"}]
        end

## Usage

    iex(1)> {:ok, pid} = EventsourceEx.new("https://url.com/stream", stream_to: self)
    {:ok, #PID<0.150.0>}
    iex(2)> flush
    %EventsourceEx.Message{data: "1", event: "message", id: nil}
    %EventsourceEx.Message{data: "2", event: "message", id: nil}
    %EventsourceEx.Message{data: "3", event: "message", id: nil}
    :ok

See [eventsource_ex_chatgpt.exs](https://github.com/wojtekmach/mix_install_examples/blob/main/eventsource_ex_chatgpt.exs) in `mix_install_examples` for a script using `eventsource_ex` to stream a response from ChatGPT.
