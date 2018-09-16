defmodule Picar do
  @moduledoc """
  Documentation for Picar.
  """

  def stop,   do: Picar.RearWheels.stop
  def faster, do: Picar.RearWheels.faster
  def slower, do: Picar.RearWheels.slower
end
