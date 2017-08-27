############################################################################
# onion_gpio.rb : binding for gpio acces in ruby 
#--------------------------------------------------------------------------
# In this version, acess are done via filefs.
# 
# benchmark : 
#   0.4 ms seconds for writing a value
#   3   ms if export/unexport on each access
#
# TODO : access par direct read/write n MIPS register
#--------------------------------------------------------------------------
# A filefs documentation: 
# http://elixir.free-electrons.com/linux/latest/source/Documentation/gpio/sysfs.txt
#
###########################################################################


########################################################################
#  Constants, for Onin/Omega architectures
########################################################################
class ConstOnionGpio
  VERSION = "1"
  GPIO_BASE_PATH= '/sys/class/gpio'
  GPIO_EXPORT   = GPIO_BASE_PATH + '/export'
  GPIO_UNEXPORT = GPIO_BASE_PATH + '/unexport'
        
  GPIO_PATH     = GPIO_BASE_PATH + '/gpio%d'
  GPIO_VALUE_FILE        ='value'
  GPIO_DIRECTION_FILE    = 'direction'
  GPIO_ACTIVE_LOW_FILE  = 'active_low'

  GPIO_INPUT_DIRECTION        = 'in'
  GPIO_OUTPUT_DIRECTION        = 'out'
  GPIO_OUTPUT_DIRECTION_LOW   = 'low'
  GPIO_OUTPUT_DIRECTION_HIGH  = 'high'

  GPIO_ACTIVE_HIGH      = 0
  GPIO_ACTIVE_LOW      = 1
end

###############" Tools ror read/write files, run process
module V1Tools
  def fwrite(*args)
    fn=args[0..-2].join("/")
    value=args.last.to_s
    puts("%-40s ==> %s" % [fn,value]) if @verbose
    open(fn,"w") {|f| f.puts(value)}
  end
  def fread(*args)
    fn=args.join("/")
    open(fn,"r") {|f| return(f.read().strip) }
  end
  def async_spawn(*args)
    puts "async_spawn : > #{args.join(' ')}" if @verbose
    pid=spawn(*(args.flatten),:chdir=>"/tmp")   
    Process.detach(pid)
  end
  def sync_spawn(*args)
    puts "sync_spawn : > #{args.join(' ')}" if @verbose
    pid=spawn(*(args.flatten),:chdir=>"/tmp")   
    Process.wait(pid)
  end
  def exec(*args)
    puts "exec : > #{args.join(' ')}" if @verbose
    system( *( args.map {|a| a.to_s} ))
  end
end

########################################################################
#  OnionGpio : digital io access : read/write/pwm
########################################################################
class OnionGpio < ConstOnionGpio
  include V1Tools
  def initialize(gpio, verbose=false)
    @gpio     = gpio
    @path     = GPIO_PATH % [ gpio ]
    @verbose   = verbose
    puts 'GPIO%d path: %s' % [@gpio, @path] if @verbose 
    @getted=0
  end
  
  def started()
    _initGpio()
  end
  def release()
    @getted=1
    _freeGpio()
  end
  
  # Write to the gpio export to make the gpio available in sysfs
  def _initGpio() 
    ( fwrite(GPIO_EXPORT,@gpio) rescue _freeGpio() )  if @getted==0
    @getted+=1
  end
  # Write to the gpio unexport to release the gpio sysfs instance
  def _freeGpio()
    fwrite(GPIO_UNEXPORT,@gpio) if @getted==1
    @getted-=1
  end
  
  def getValue()
    _initGpio()
    ret=fread(@path,GPIO_VALUE_FILE)
    _freeGpio()
    ret
  end

  def setValue(value)
    _initGpio()
    ret=fwrite(@path,GPIO_VALUE_FILE,value)
    _freeGpio()
  end

  # direction functions
  def getDirection()
    _initGpio()
    ret=fread(@path,GPIO_DIRECTION_FILE)
    _freeGpio()
    ret
  end

  def _setDirection(direction)
    # check the direction argument
    if direction != GPIO_INPUT_DIRECTION and direction != GPIO_OUTPUT_DIRECTION and direction != GPIO_OUTPUT_DIRECTION_LOW and direction != GPIO_OUTPUT_DIRECTION_HIGH
      raise("setDirection() : invalide value for direction: '#{direction}'")
    end
    
    _initGpio()
    fwrite(@path,GPIO_DIRECTION_FILE,direction)
    setValue(0) if direction == GPIO_OUTPUT_DIRECTION
    _freeGpio()
  end
  
  def setInputDirection() _setDirection(GPIO_INPUT_DIRECTION) end
  def setOutputDirection(initial=-1)
    argument  = GPIO_OUTPUT_DIRECTION
    argument  = case initial
     when 0 then GPIO_OUTPUT_DIRECTION_LOW
     when 1 then GPIO_OUTPUT_DIRECTION_HIGH
     else
      GPIO_OUTPUT_DIRECTION
    end
    _setDirection(argument)
  end

=begin
  # active-low functions
  def getActiveLow()
    _initGpio()
    activeLow=fread(@path,GPIO_ACTIVE_LOW_FILE)
    fwrite(@path,GPIO_DIRECTION_FILE,direction)
    setValue(0) if direction == GPIO_OUTPUT_DIRECTION
    _freeGpio()
  end

  def _setActiveLow(activeLow)
     raise("") if activeLow != GPIO_ACTIVE_HIGH && activeLow != GPIO_ACTIVE_LOW
    _initGpio()
    fwrite(@path,GPIO_ACTIVE_LOW_FILE)
    _freeGpio()
  end
  
  def setActiveHigh()     _setActiveLow(GPIO_ACTIVE_HIGH) end
  def setActiveLow()      _setActiveLow(GPIO_ACTIVE_LOW) end
=end

  # period 		= (1.0f/freq) * 1000;
  # dutyCycle = duty / 100.0f;
  # periodHigh	= period * dutyCycle;
  # periodLow = period - periodHigh; //can also be: period * (1.0f - dutyCycle);
  def pwm_set(frequency,on_ratio)
    r=on_ratio.to_i 
   
    puts "pwm #{@gpio} => set to f=#{frequency} pulse=#{r}%" if @verbose
    async_spawn( "fast-gpio","pwm",@gpio.to_s,frequency.to_s,(r < 0 ? 0 : (r > 100 ?  100 : r)).to_s)   
  end
  def pwm_reset()
    pwm_set(0,0)
    setValue(0)
  end
end


########################################################################
# I2C : commands line I2C via i2cget i2cset i2cdetect
########################################################################
class OnionI2C < ConstOnionGpio
  include V1Tools

  def initialize(gpio, verbose=false)
    @gpio     = gpio
    @verbose   = verbose
    puts 'I2C%d path: %s' % [@gpio, @path] if @verbose 
    @getted=0
  end
  def show_detect(no=3)
     puts exec("i2cdetect -y #{@gpio}")
  end 
  def show_registers_bytes(no=3)
     puts exec("i2cdump -y #{@gpio} #{no} b")
  end 
  def show_registers_words(no=3)
     puts exec("i2cdump -y #{@gpio} #{no} w")
  end 
  def read_register_byte(no,address)
    ret=exec("i2cget","-y",@gpio.to_s,no.to_s,"0x%02X" % address,"b")
  end
  def read_register_word(no,address)
    ret=exec("i2cget","-y",@gpio.to_s,no.to_s,"0x%02X" % address,"w")
  end
end

########################################################################
# Oled
#    Tested with a 128x64 Oled Goove (seedStudio)
#    Should work with Onion OledExp
########################################################################
class OnionOled < ConstOnionGpio
  include V1Tools
   
  def initialize(i2c,noi2c, verbose=false)
    @i2c       = i2c
    @noi2c     = noi2c
    @verbose   = verbose
    @opt=["-q"]
    #@opt=["-v"] if verbose
    puts('OLED(%d,%d) ' % [@i2c,@noi2c]) if @verbose 
  end
  def reset()          sync_spawn("oled-exp","-c","power","on") end
  def clear()          sync_spawn("oled-exp","-c","cursor","1,1") end
  def pos(x,y,t="")    sync_spawn("oled-exp",@opt,"cursor","#{y+1},#{x+1}","write",t.to_s) end
  def write_at(x,y,text="") sync_spawn("oled-exp",@opt,"cursor","#{y+1},#{x+1}","write",text.to_s) end
  def write_text(text) sync_spawn("oled-exp",@opt,"write",text) end
  def write(text)      sync_spawn("oled-exp",@opt,"write",text) end
  def write_byte(value)sync_spawn("oled-exp",@opt,"writeByte",value.to_s) end
  def invert(on)       sync_spawn("oled-exp",@opt,"invert", on ? "on" : "off") end
  def bright(on)       sync_spawn("oled-exp",@opt,"dim", on ? "off" : "on") end
  def cascad(lcmd)     sync_spawn("oled-exp",@opt,"cascad",*(lcmd.map {|a|i a.to_s}) ) end

  def write_raster_file(fn)
    raise("File not exist") unless File.file?(fn)
    sync_spawn("oled-exp",@opt,"draw",fn)
  end
end

############################ T e s t s ################################

if $0 == __FILE__

  def chrono(nb=1)
     start=Time.now
     nb.times {|i| yield(i) }
     eend=Time.now
     puts "Duration: #{((eend.to_f-start.to_f)*1000)/nb} ms"
  end
  def mp(*args)
    puts "\n\n#{'#'*40}" if args.size>0 && args.first[0]=="#"
    args.each {|s| puts s.to_s }
    puts "#{'#'*40}\n" if args.size>0 && args.first[0]=="#"
  end 

  mp("# OLED Test")
  oled=OnionOled.new(0,0,true)
  oled.reset
  oled.write_text("CouCou") ; sleep(1)
  oled.pos(0,1)
  3.times { oled.write_text(Time.now.to_s.split(' ')[1]) ; sleep(1) }
  
  20.times {|x|
    oled.pos(x,2+x%2,'X')
    sleep(1)
  }

  mp("# PWM Test")
  pwm=OnionGpio.new( (ARGV.shift || "3").to_i ,true) 
  pwm.pwm_set(2,20)
  sleep(5)
  pwm.pwm_reset()
  chrono(100) { |i|  pwm.pwm_set(2,i) }
  pwm.pwm_reset()

  mp("# Gpio digital io  Test")
  gpio=OnionGpio.new( (ARGV.shift || "3").to_i, false)
  gpio.setOutputDirection()
  10.times { |i| gpio.setValue(i%2) ; sleep 0.1}
  chrono(100) { |i| gpio.setValue(i%2) } 
  gpio.started
  chrono(100) { |i| gpio.setValue(i%2) } 
  gpio.release
end

