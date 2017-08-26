########################################################################
#  oled : test oled
########################################################################
require_relative "onion-gpio"

oled=OnionOled.new(0,0)
oled.reset
oled.pos(0,0,ARGV.join(' ')) 
loop {
   oled.pos(10,5,Time.now.to_s.split(' ')[1]) ; sleep(1) 
}
