defmodule PicarTest do
  use ExUnit.Case
  doctest Picar

  test "greets the world" do
    assert Picar.hello() == :world
  end
end
