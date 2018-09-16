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
      i2c_device: "i2c-1",
      i2c_address: 0x40,
      i2c_pid: None,
      gpio_pid_motor_a: None,
      gpio_pid_motor_b: None,
      freq: 60,
      speed: 0
    }

    pid = PWM.start
    PWM.init(pid)
    PWM.prescale(pid, state.freq)
    PWM.set_pwm_ab(pid)

    PWM.set_pwm(pid, @pwma, 0, 0)
    PWM.set_pwm(pid, @pwmb, 0, 0)

    {:ok, gpio_pid_motor_a} = GPIO.start_link @motor_a_dir_gpio, :output
    {:ok, gpio_pid_motor_b} = GPIO.start_link @motor_b_dir_gpio, :output

    {:ok, %{state | i2c_pid: pid, gpio_pid_motor_a: gpio_pid_motor_a, gpio_pid_motor_b: gpio_pid_motor_b}}
  end 


  @impl true
  def handle_call(:stop, _from, state) do
    PWM.set_pwm(state.i2c_pid, @pwma, 0, 0)
    PWM.set_pwm(state.i2c_pid, @pwmb, 0, 0)

    reply = {:ok, %{speed: 0}}
    new_state =  %{state | speed: 0}
    {:reply, reply, new_state}
  end

  def handle_call({:change_speed, speed_delta}, _from, %{speed: speed} = state) do

    new_speed = speed + speed_delta

    PWM.set_pwm(state.i2c_pid, @pwma, 0, new_speed)
    PWM.set_pwm(state.i2c_pid, @pwmb, 0, new_speed)

    Logger.debug "Speed set to #{new_speed}"

    reply = {:ok, %{speed: new_speed}}
    new_state =  %{state | speed: new_speed}
    {:reply, reply, new_state}
  end

end

