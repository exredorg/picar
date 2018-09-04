defmodule Picar.RearWheels do

  require Logger
  use GenServer
  alias Picar.PWM

  @pwma  4
  @pwmb  5


  # API
  #####################

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  def faster do
    GenServer.call(__MODULE__, :faster)
  end


  # Callbacks
  #####################

  @impl true
  def init(_args) do
    Logger.debug "Starting..."

    state = %{
      i2c_device: "i2c-1",
      i2c_address: 0x40,
      i2c_pid: None,
      freq: 1600,
      speed: 0
    }

    pid = PWM.start
    PWM.init(pid)
    PWM.prescale(pid, state.freq)
    PWM.set_pwm_ab(pid)

    PWM.set_pwm(pid, @pwma, 0, 0)
    PWM.set_pwm(pid, @pwmb, 0, 0)

    {:ok, %{state | i2c_pid: pid}}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    PWM.set_pwm(state.i2c_pid, @pwma, 0, 0)
    PWM.set_pwm(state.i2c_pid, @pwmb, 0, 0)

    reply = {:ok, %{speed: 0}}
    new_state =  %{state | speed: 0}
    {:reply, reply, new_state}
  end

  def handle_call(:faster, _from, state) do
    new_speed = state.speed + 100

    PWM.set_pwm(state.i2c_pid, @pwma, 0, new_speed)
    PWM.set_pwm(state.i2c_pid, @pwmb, 0, new_speed)

    Logger.debug "Speed set to #{new_speed}"

    reply = {:ok, %{speed: new_speed}}
    new_state =  %{state | speed: new_speed}
    {:reply, reply, new_state}
  end
end

