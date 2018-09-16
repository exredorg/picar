defmodule Picar.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application


  
  @i2c_device "i2c-1"
  @i2c_address 0x40


  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      %{
        id: I2C,
        start: {ElixirALE.I2C, :start_link, [@i2c_device, @i2c_address, [name: :i2c]]}
      },
      {Picar.PWM, []},
      {Picar.RearWheels, []},
      {Picar.FrontWheels, []}

      # Starts a worker by calling: Picar.Worker.start_link(arg)
      # {Picar.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Picar.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
