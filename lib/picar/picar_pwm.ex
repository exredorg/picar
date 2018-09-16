defmodule Picar.PWM.Old do
  @moduledoc """
  functions to interact with a pwm card over I2C
  """

  require Logger
  use Bitwise 
  alias ElixirALE.I2C


  @mode1      0x00 # bit 4 is SLEEP 000X0000
  @mode2      0x01
  @prescale   0xFE

  @all_on_l   0xFA
  @all_on_h   0xFB
  @all_off_l  0xFC
  @all_off_h  0xFD

  @led0_on_l  0x06
  @led0_on_h  0x07
  @led0_off_l 0x08
  @led0_off_h 0x09
  
  @allcall 0x01
  @outdrv 0x04
  @swrst 0x06

  # These seem to be some of the 16 channels on the PCA9685
  # I think the diagrams in the tutorial show how the PCA9685 is connected to the TB6612's on the board
  # https://learn.adafruit.com/adafruit-dc-and-stepper-motor-hat-for-raspberry-pi?view=all
  # @pwma  8
  # @ain2  9
  # @ain1  10
  # @pwmb  13
  # @bin2  12
  # @bin1  11

  @pwma  4
  @pwmb  5

  @ain2  9
  @ain1  10
  @bin2  12
  @bin1  11


 
  # PCA9685 Software Reset (Section 7.6 on pg 28)
  def swrst do
    Logger.debug "PCA9685 Software Reset..."
    {:ok,pid}=I2C.start_link("i2c-1", 0x00)
    :timer.sleep 10
    I2C.write(pid,<<@swrst>>)
  end


  def start do
    Logger.debug "Starting..."
    {:ok,pid}= I2C.start_link("i2c-1", 0x40)
    pid
  end


  def init(pid) do
    Logger.debug "Initializing..."
    
    set_all_pwm(pid,0,0) 

    I2C.write(pid, <<@mode2, @outdrv>>) # external driver, see docs
    I2C.write(pid, <<@mode1, @allcall>>) # program all PCA9685's at once
    :timer.sleep 5 
  end


  def prescale(pid,freq) do
    Logger.debug "Setting prescale to #{freq} Hz" 

    # pg 14 and solve for prescale or example on pg 25
    prescaleval = trunc(Float.round( 25000000.0 / 4096.0 / freq ) - 1 )
    Logger.debug "prescale value is #{prescaleval}"

    oldmode = I2C.write_read(pid, <<@mode1>>, 1)
    :timer.sleep 5
    I2C.write(pid, <<@mode1, 0x11>>) # set bit 4 (sleep) to allow setting prescale
    I2C.write(pid, <<@prescale, prescaleval>> )
    I2C.write(pid, <<@mode1, 0x01>> ) #un-set sleep bit
    :timer.sleep 5 # pg 14 it takes 500 us for the oscillator to be ready

    I2C.write(pid, <<@mode1>> <> oldmode ) # put back old mode

  end

  def step_one(pid) do
    set_pin(pid,@ain2,1)
    set_pin(pid,@bin1,1)
    set_pin(pid,@ain1,0)
    set_pin(pid,@bin2,0)
  end
 
  def step_two(pid) do
    set_pin(pid,@ain2,0)
    set_pin(pid,@bin1,1)
    set_pin(pid,@ain1,1)
    set_pin(pid,@bin2,0)
  end

  def step_three(pid) do
    set_pin(pid,@ain2,0)
    set_pin(pid,@bin1,0)
    set_pin(pid,@ain1,1)
    set_pin(pid,@bin2,1)
  end

  def step_four(pid) do
    set_pin(pid,@ain2,1)
    set_pin(pid,@bin1,0)
    set_pin(pid,@ain1,0)
    set_pin(pid,@bin2,1)
  end

  def stop(pid) do
    Logger.debug "stopping..."
    set_pin(pid,@ain2,0)
    set_pin(pid,@bin1,0)
    set_pin(pid,@ain1,0)
    set_pin(pid,@bin2,0)
  end

  def stop2(pid) do
    Logger.debug "Stopping... (setting pwm to 0)"
    set_pwm(pid, @pwma, 0, 0)
    set_pwm(pid, @pwmb, 0, 0)
  end

  def turn(pid) do
    turn(pid, 5)
  end

  def turn(pid,0) do
    stop(pid)
  end

  def turn(pid, count) do
    Logger.debug "turning... #{count}"
    step_one(pid)
    :timer.sleep 10
    step_two(pid)
    :timer.sleep 10
    step_three(pid)
    :timer.sleep 10
    step_four(pid)
    :timer.sleep 10
    turn(pid, count-1) 
  end

  def set_pin(pid,channel,0) do
    set_pwm(pid,channel,0,0x1000)
  end

  def set_pin(pid,channel,1) do
    set_pwm(pid,channel,0x1000,0)
  end

  # These don't need to change unless you are micro-stepping
  def set_pwm_ab(pid) do
    set_pwm(pid, @pwma, 0, 0x0FF0)
    set_pwm(pid, @pwmb, 0, 0x0FF0)  
  end

  # The registers for each of the 16 channels are sequential
  # so the address can be calculated as an offset from the first one
  def set_pwm(pid, channel, on, off) do
    I2C.write(pid, <<@led0_on_l+4*channel, on &&& 0xFF>>)
    I2C.write(pid, <<@led0_on_h+4*channel, on >>> 8>>)
    I2C.write(pid, <<@led0_off_l+4*channel, off &&& 0xFF>>) 
    I2C.write(pid, <<@led0_off_h+4*channel, off >>> 8>>)
  end

  # The PCA9685 has special registers for setting ALL channels
  # (or 1/3 of them) to the same value. 
  def set_all_pwm(pid, on, off) do
    I2C.write(pid, <<@all_on_l, on &&& 0xFF>>)
    I2C.write(pid, <<@all_on_h, on >>> 8>>)
    I2C.write(pid, <<@all_off_l, off &&& 0xFF>>)
    I2C.write(pid, <<@all_off_h, off >>> 8>>)
  end
end
   
