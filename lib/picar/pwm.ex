defmodule Picar.PWM do
  @moduledoc """
  functions to interact with a pwm card over I2C
  """

  require Logger
  use Bitwise 
  use GenServer
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


  # API
  # #####################

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end
  
  def set(channel, on, off) do
    GenServer.call(__MODULE__, {:set, channel, on, off})
  end

  def set_all(on, off) do
    GenServer.call(__MODULE__, {:set_all, on, off})
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end


  # Callbacks
  # ####################
  
  @impl True
  def init([]) do
    Logger.debug "Initializing..."
    
    set_all_pwm(0,0) 

    I2C.write(:i2c, <<@mode2, @outdrv>>) # external driver, see docs
    I2C.write(:i2c, <<@mode1, @allcall>>) # program all PCA9685's at once
    :timer.sleep 5 
    {:ok, %{}}
  end


  @impl True
  def handle_call({:set, channel, on, off}, _from, state) do
    res = set_pwm(channel, on, off)
    {:reply, res, state}
  end


  def handle_call({:set_all, on, off}, _from, state) do
    res = set_all_pwm(on, off)
    {:reply, res, state}
  end


  def handle_call(:reset, _from, state) do
    swrst()
    {:stop, :pwm_reset, :pwm_reset_requested, state}
  end



  # Implementation
  # ####################

  def prescale(freq) do
    Logger.debug "Setting prescale to #{freq} Hz" 

    # pg 14 and solve for prescale or example on pg 25
    prescaleval = trunc(Float.round( 25000000.0 / 4096.0 / freq ) - 1 )
    Logger.debug "prescale value is #{prescaleval}"

    oldmode = I2C.write_read(:i2c, <<@mode1>>, 1)
    :timer.sleep 5
    I2C.write(:i2c, <<@mode1, 0x11>>) # set bit 4 (sleep) to allow setting prescale
    I2C.write(:i2c, <<@prescale, prescaleval>> )
    I2C.write(:i2c, <<@mode1, 0x01>> ) #un-set sleep bit
    :timer.sleep 5 # pg 14 it takes 500 us for the oscillator to be ready

    I2C.write(:i2c, <<@mode1>> <> oldmode ) # put back old mode
  end


  # The registers for each of the 16 channels are sequential
  # so the address can be calculated as an offset from the first one
  def set_pwm(channel, on, off) do
    I2C.write(:i2c, <<@led0_on_l+4*channel, on &&& 0xFF>>)
    I2C.write(:i2c, <<@led0_on_h+4*channel, on >>> 8>>)
    I2C.write(:i2c, <<@led0_off_l+4*channel, off &&& 0xFF>>) 
    I2C.write(:i2c, <<@led0_off_h+4*channel, off >>> 8>>)
  end


  # The PCA9685 has special registers for setting ALL channels
  # (or 1/3 of them) to the same value. 
  def set_all_pwm(on, off) do
    I2C.write(:i2c, <<@all_on_l, on &&& 0xFF>>)
    I2C.write(:i2c, <<@all_on_h, on >>> 8>>)
    I2C.write(:i2c, <<@all_off_l, off &&& 0xFF>>)
    I2C.write(:i2c, <<@all_off_h, off >>> 8>>)
  end

  # PCA9685 Software Reset (Section 7.6 on pg 28)
  def swrst do
    Logger.debug "PCA9685 Software Reset..."
    {:ok,pid}=I2C.start_link("i2c-1", 0x00)
    :timer.sleep 10
    I2C.write(pid,<<@swrst>>)
  end

end
   
