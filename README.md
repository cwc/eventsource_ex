# EventsourceEx

An Elixir EventSource (Server-Sent Events) client

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

## Troubleshooting

Please note, that browsers are limited to 6 connections per domain. [More info]()https://stackoverflow.com/questions/5195452/websockets-vs-server-sent-events-eventsource).
