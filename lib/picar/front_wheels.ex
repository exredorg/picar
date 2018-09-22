defmodule Picar.FrontWheels do

  require Logger
  use GenServer
  alias Picar.PWM

  @pwm_ch  0
  @min_pulse_width 600
  @max_pulse_width 2400
  @default_pulse_width 1500
  @frequency 60
  @angle_offset -2


  # API
  #####################

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  def test,  do: GenServer.call(__MODULE__, :test)
  def test2, do: GenServer.call(__MODULE__, :test2)
  def test3, do: GenServer.call(__MODULE__, :test3)
  
  def left(angle), do: GenServer.call(__MODULE__, {:set_target, 90-angle)
  def right(angle), do: GenServer.call(__MODULE__, {:set_target, 90+angle)
  def straight, do: GenServer.call(__MODULE__, {:set_target, 90)

  # Callbacks
  #####################

  @impl true
  def init(_args) do
    Logger.debug "Starting..."

    state = %{
      freq: 60,
      current_angle: 90,
      target_angle: 90
    }

    straight = angle_to_analog(90)
    Logger.debug "Turning straight (#{straight})"
    PWM.set(@pwm_ch, 0, angle_to_analog(state.current_angle))
    :timer.sleep(1000)

    {:ok, state, 200}
  end 


  @impl true
  def handle_info(:timeout, %{current_angle: ca, target_angle: ta} = state) do
    # turn front wheel one step closer to target
    if ta == ca do
      {:noreply, state, 200}
    else
      new_ca = ca + abs(ta-ca)*5
      {:noreply, %{state | current_angle: new_ca}}
    end
  end


  @impl true
  def handle_call({:set_target, angle}, _from, state) do
    if angle>=45 and angle <=135 do
      Logger.debug "Target angle set to #{angle}"
      {:ok, %{state| target_angle: angle}, 200}
    else
      Logger.debug "Target angle #{angle} refused"
      {:refused, state, 200}
    end
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

  def handle_call(:test3, _from, state) do
    straight = 90
    left = 70
    right = 110
    
    Logger.debug "Turning straight (#{straight})"
    PWM.set(@pwm_ch, 0, angle_to_analog(straight))
    :timer.sleep(500)

    Logger.debug "Turning left (#{left})"
    for angle <- straight..left, &(rem(&1,5) == 0) do
      PWM.set(@pwm_ch, 0, angle_to_analog(angle))
      :timer.sleep(100)
    end
    for angle <- left..straight, &(rem(&1,5) == 0) do
      PWM.set(@pwm_ch, 0, angle_to_analog(angle))
      :timer.sleep(100)
    end

    Logger.debug "Turning right (#{right})"
    for angle <- straight..right, &(rem(&1,5) == 0) do
      PWM.set(@pwm_ch, 0, angle_to_analog(angle))
      :timer.sleep(100)
    end
    for angle <- right..straight, &(rem(&1,5) == 0) do
      PWM.set(@pwm_ch, 0, angle_to_analog(angle))
      :timer.sleep(100)
    end

    Logger.debug "Turning straight (#{straight})"
    PWM.set(@pwm_ch, 0, angle_to_analog(straight))

    {:reply, :ok, state}
  end


  def angle_to_analog(angle) do
    pulse_width = (angle + @angle_offset) / 180 * (@max_pulse_width - @min_pulse_width) + @min_pulse_width
    analog_value = round(pulse_width / 1000000 * @frequency * 4096)
  end

end

