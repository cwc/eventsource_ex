defmodule EventsourceEx.Message do
  defstruct id: nil, event: "message", data: nil

  @type t :: struct
end
