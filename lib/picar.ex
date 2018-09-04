defmodule Picar do
  @moduledoc """
  Documentation for Picar.
  """

  def stop do
    Picar.RearWheels.stop
  end

  def faster do
    Picar.RearWheels.faster
  end

end
