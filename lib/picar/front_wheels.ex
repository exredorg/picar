defmodule Picar.FrontWheels do

  require Logger
  use GenServer
  alias Picar.PWM

  @pwm_ch  0
  @min_pulse_width 600
  @max_pulse_width 2400
  @default_pulse_width 1500
  @frequency 60


  # API
  #####################

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  def test do
    GenServer.call(__MODULE__, :test)
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
      freq: 60,
      speed: 0
    }

    pid = PWM.start
    PWM.init(pid)
    PWM.prescale(pid, state.freq)
    PWM.set_pwm_ab(pid)

    # PWM.set_pwm(pid, @pwm_ch, 0, 0)

    {:ok, %{state | i2c_pid: pid}}
  end 


  @impl true
  def handle_call({:set_angle, angle}, _from, %{angle: angle} = state) do

    new_speed = 10

    #PWM.set_pwm(state.i2c_pid, @pwma, 0, new_speed)
    #PWM.set_pwm(state.i2c_pid, @pwmb, 0, new_speed)

    Logger.debug "Speed set to #{new_speed}"

    reply = {:ok, %{speed: new_speed}}
    new_state =  %{state | speed: new_speed}
    {:reply, reply, new_state}
  end

  def handle_call(:test, _from, state) do
    straight = angle_to_analog(90)
    left = angle_to_analog(70)
    right = angle_to_analog(110)
    
    Logger.debug "Turning straight (#{straight})"
    PWM.set_pwm(state.i2c_pid, @pwm_ch, 0, straight)
    :timer.sleep(1000)

    Logger.debug "Turning left (#{left})"
    PWM.set_pwm(state.i2c_pid, @pwm_ch, 0, left)
    :timer.sleep(1000)

    Logger.debug "Turning right (#{right})"
    PWM.set_pwm(state.i2c_pid, @pwm_ch, 0, right)
    :timer.sleep(1000)

    Logger.debug "Turning straight (#{straight})"
    PWM.set_pwm(state.i2c_pid, @pwm_ch, 0, straight)

    {:noreply, state}
  end



  def angle_to_analog(angle) do
    pulse_width = angle / 180 * (@max_pulse_width - @min_pulse_width) + @min_pulse_width
    analog_value = round(pulse_width / 1000000 * @frequency * 4096)
  end

end

