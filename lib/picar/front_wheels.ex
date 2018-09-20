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

  def test2 do
    GenServer.call(__MODULE__, :test2)
  end
  

  # Callbacks
  #####################

  @impl true
  def init(_args) do
    Logger.debug "Starting..."

    state = %{
      freq: 60,
      speed: 0
    }

    straight = angle_to_analog(90)
    Logger.debug "Turning straight (#{straight})"
    PWM.set(@pwm_ch, 0, 0)
    :timer.sleep(1000)

    {:ok, state}
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
    PWM.set(@pwm_ch, 0, straight)
    :timer.sleep(500)

    Logger.debug "Turning left (#{left})"
    PWM.set(@pwm_ch, 0, left)
    :timer.sleep(500)

    Logger.debug "Turning right (#{right})"
    PWM.set(@pwm_ch, 0, right)
    :timer.sleep(500)

    Logger.debug "Turning straight (#{straight})"
    PWM.set(@pwm_ch, 0, straight)

    {:reply, :ok, state}
  end

  def handle_call(:test2, _from, state) do
    straight = angle_to_analog(90)
    
    Logger.debug "Turning straight (#{straight})"
    PWM.set(@pwm_ch, 0, straight)
    :timer.sleep(100)
    Logger.debug "Done"

    {:reply, :ok, state}
  end




  def angle_to_analog(angle) do
    pulse_width = angle / 180 * (@max_pulse_width - @min_pulse_width) + @min_pulse_width
    analog_value = round(pulse_width / 1000000 * @frequency * 4096)
  end

end

