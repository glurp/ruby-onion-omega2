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
require_relative 'utils.rb'

class ConstOnionGpio
  VERSION = "1"
  GPIO_BASE_PATH= '/sys/class/gpio'
  GPIO_EXPORT 	= GPIO_BASE_PATH + '/export'
  GPIO_UNEXPORT = GPIO_BASE_PATH + '/unexport'
        
  GPIO_PATH 		= GPIO_BASE_PATH + '/gpio%d'
  GPIO_VALUE_FILE			  ='value'
  GPIO_DIRECTION_FILE	  = 'direction'
  GPIO_ACTIVE_LOW_FILE	= 'active_low'

  GPIO_INPUT_DIRECTION			  = 'in'
  GPIO_OUTPUT_DIRECTION			  = 'out'
  GPIO_OUTPUT_DIRECTION_LOW   = 'low'
  GPIO_OUTPUT_DIRECTION_HIGH	= 'high'

  GPIO_ACTIVE_HIGH			= 0
  GPIO_ACTIVE_LOW			= 1
end


class OnionGpio < ConstOnionGpio
	def initialize(gpio, verbose=false)
		@gpio 		= gpio
		@path 		= GPIO_PATH % [ gpio ]
		@verbose 	= verbose
	  puts 'GPIO%d path: %s' % [@gpio, @path] if @verbose 
		@getted=0
  end
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
		argument	= GPIO_OUTPUT_DIRECTION
		argument	= case initial
     when 0 then GPIO_OUTPUT_DIRECTION_LOW
     when 1 then GPIO_OUTPUT_DIRECTION_HIGH
     else
      GPIO_OUTPUT_DIRECTION
    end
		_setDirection(argument)
  end

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

end

if $0 == __FILE__
  gpio=OnionGpio.new( (ARGV.shift || "3").to_i, false)
  gpio.setOutputDirection()
  10.times { |i| gpio.setValue(i%2) ; sleep 0.1}
  chrono(1000) { |i| gpio.setValue(i%2) } 
  gpio.started
  chrono(1000) { |i| gpio.setValue(i%2) } 
  gpio.release
end

