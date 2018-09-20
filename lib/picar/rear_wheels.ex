defmodule Picar.RearWheels do

  require Logger
  use GenServer
  alias Picar.PWM
  alias ElixirALE.GPIO


  @pwma  4
  @pwmb  5
  @motor_a_dir_gpio 17
  @motor_b_dir_gpio 27
  @forward 0
  @backward 1



  # API
  #####################

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  def faster do
    GenServer.call(__MODULE__, {:change_speed, +100})
  end

  def slower do
    GenServer.call(__MODULE__, {:change_speed, -100})
  end

  def forward do 
    GenServer.call(__MODULE__, {:change_direction, @forward})
  end

  def backward do 
    GenServer.call(__MODULE__, {:change_direction, @backward})
  end

  

  # Callbacks
  #####################

  @impl true
  def init(_args) do
    Logger.debug "Starting..."

    state = %{
      gpio_pid_motor_a: None,
      gpio_pid_motor_b: None,
      freq: 60,
      direction: @forward,
      speed: 0
    }

    PWM.prescale(state.freq)
    PWM.set(@pwma, 0, 0)
    PWM.set(@pwmb, 0, 0)

    {:ok, gpio_pid_motor_a} = GPIO.start_link @motor_a_dir_gpio, :output
    {:ok, gpio_pid_motor_b} = GPIO.start_link @motor_b_dir_gpio, :output
    GPIO.write gpio_pid_motor_a, @forward
    GPIO.write gpio_pid_motor_b, @forward

    {:ok, %{state | gpio_pid_motor_a: gpio_pid_motor_a, gpio_pid_motor_b: gpio_pid_motor_b}}
  end 


  @impl true
  def handle_call(:stop, _from, state) do
    PWM.set(@pwma, 0, 0)
    PWM.set(@pwmb, 0, 0)

    reply = {:ok, %{speed: 0}}
    new_state =  %{state | speed: 0}
    {:reply, reply, new_state}
  end

  def handle_call({:change_speed, speed_delta}, _from, %{speed: speed} = state) do
    new_speed = speed + speed_delta

    PWM.set(@pwma, 0, new_speed)
    PWM.set(@pwmb, 0, new_speed)

    Logger.debug "Speed set to #{new_speed}"

    reply = {:ok, %{speed: new_speed}}
    new_state =  %{state | speed: new_speed}
    {:reply, reply, new_state}
  end

  def handle_call({:change_direction, @forward}, _from, %{direction: @forward} = state) do 
    {:reply, {:ok, :unchanged}, state}
  end
 
  def handle_call({:change_direction, @backward}, _from, %{direction: @backward} = state) do 
    {:reply, {:ok, :unchanged}, state}
  end

  def handle_call({:change_direction, new_direction}, _from, %{speed: speed} = state) 
  when speed > 1000 do
    {:reply, {:error, :rejected_too_fast}, state}
  end

  def handle_call({:change_direction, new_direction}, _from, state) do
    Logger.debug "Changing direction ..."

    PWM.set(@pwma, 0, 0)
    PWM.set(@pwmb, 0, 0)

    Logger.debug "Speed set to 0"

    :timer.sleep(200)

    GPIO.write state.gpio_pid_motor_a, new_direction
    GPIO.write state.gpio_pid_motor_b, new_direction

    Logger.debug "Changed direction to #{new_direction}"

    new_state = %{ state |
      speed: 0,
      direction: new_direction
    }

    {:reply, {:ok, new_direction}, new_state}
  end

end

