defmodule EventsourceEx.Message do
  defstruct id: nil, event: "message", data: nil, dispatch_ts: nil

  @type t :: struct
end
