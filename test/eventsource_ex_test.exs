defmodule EventsourceExTest do
  use ExUnit.Case

  import Mox

  setup :set_mox_from_context

  test "follows events" do
    EventsourceExTest.HTTPoisonMock
    |> expect(:get!, fn url, _headers, options ->
      assert url == "https://a.test"
      target = options[:stream_to]

      [
        ":ok\n\n",
        "event: message\n",
        "data: 1\n\n",
        "event: message\n",
        "data: 2\n\n",
        "id: 3\n",
        "data: 3\n\n",
        "id: 4\ndata: 4",
        "\n\n",
        "data: fi",
        "ve\n\n",
        "data: 6\n",
        "data: 7\n\n"
      ]
      |> Enum.map(&send(target, %{chunk: &1}))
    end)

    EventsourceEx.new("https://a.test",
      stream_to: self(),
      adapter: EventsourceExTest.HTTPoisonMock
    )

    assert_receive(%EventsourceEx.Message{data: "1", event: "message"})
    assert_receive(%EventsourceEx.Message{data: "2", event: "message"})
    assert_receive(%EventsourceEx.Message{id: "3", data: "3", event: "message"})
    assert_receive(%EventsourceEx.Message{id: "4", data: "4", event: "message"})
    assert_receive(%EventsourceEx.Message{data: "five", event: "message"})
    assert_receive(%EventsourceEx.Message{data: "6\n7", event: "message"})

    verify!()
  end

  test "follows events from a post request" do
    EventsourceExTest.HTTPoisonMock
    |> expect(:post!, fn url, _headers, _body, options ->
      assert url == "https://a.test"
      target = options[:stream_to]

      [
        ":ok\n\n",
        "event: message\n",
        "data: 1\n\n",
        "event: message\n",
        "data: 2\n\n",
        "id: 3\n",
        "data: 3\n\n",
        "id: 4\ndata: 4",
        "\n\n",
        "data: fi",
        "ve\n\n",
        "data: 6\n",
        "data: 7\n\n"
      ]
      |> Enum.map(&send(target, %{chunk: &1}))
    end)

    EventsourceEx.new("https://a.test",
      stream_to: self(),
      adapter: EventsourceExTest.HTTPoisonMock,
      method: :post
    )

    assert_receive(%EventsourceEx.Message{data: "1", event: "message"})
    assert_receive(%EventsourceEx.Message{data: "2", event: "message"})
    assert_receive(%EventsourceEx.Message{id: "3", data: "3", event: "message"})
    assert_receive(%EventsourceEx.Message{id: "4", data: "4", event: "message"})
    assert_receive(%EventsourceEx.Message{data: "five", event: "message"})
    assert_receive(%EventsourceEx.Message{data: "6\n7", event: "message"})

    verify!()
  end
end
