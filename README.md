Presentation
============

Discovered Omega2+, OpenWrt with 128MB for 10€ , I try it with ruby Lang.
* 128 MB RAM, 32 MB EPROM, 12 MB free after ruby install
* openWrt/ ELED
* Pins for One ethernet port, wifi
* 5$ (32MB RAM) or 10$ (128 MB RAM)


The concurrents seems to be :
* Linkit smart : very near Onion product ( 12$ ), with Atmel chip for Arduino-compatibility
* Olimex RT5350 : 32MB RAM, with 5 Ethernets ports ( 15$ € )
* Arduino yun : more expensive ( 50$ ) 1 Ethernet, 64MB RAM
* RAK633 : 64MB RAM, 5 Ethernets ports, MT7628  , 10$ (? aliexpress)
* Banana PI RT1 : 5 Ethernets ports,512MB RAM, more more expensive (70$ ?)

Developer Plan
==============

Previsions :
------------

* V1 : develop this material without C librairie : use sysfs and some Onion exec (```fast-gpio``` ...)
* V2 : link to onionlib shared library via FFI, provide same API as V1, but faster
* V3 : make a onion-mruby executable with all V2 io included :-)

Currently: V1 only :)

TODO on V1 :
------------

* [x] develop a gpio library for digital input/output access
* [x] develop a pwm library using fast-gpio
* [x] OLED access ion I2C: seem ok with SSD1308 based Oled (text write, reset...)
* [x] OLED create SSD130x file format from ppm file, send it to oled display
* [ ] I2C
* [ ] uart
* [ ] gem ! ( actually, requiring ```onion-gpio.rb``` is sufficient)



Feel free to collaborate to the project !




Ruby use on Omega2+
====================

no difficulties :
```
> opkg intall ruby
> opkg install rubygems
```

This represent 5MB on flash memory, at ```/usr/lib/ruby```.
```
~# du -s /usr/lib/ruby/*
5078    /usr/lib/ruby/2.4
156     /usr/lib/ruby/gems
5       /usr/lib/ruby/ruby2.4-bin
0       /usr/lib/ruby/site_ruby
0       /usr/lib/ruby/vendor_ruby
```



onion-gpio.rb
=============
Use sysfs for access to digital gpio (duration: 3ms for writing one output line).

Use programs like fast-gpio, oled-exp an i2c-get for other access.



Example
=======

```ruby
# put a LED pn port 3,

require_relative 'ionion-gpio.rb'

gpio=OnionGpio.new( 3 , false)
gpio.setOutputDirection()
100.times { |i| gpio.setValue(i%2) ; sleep 0.1}
gpio.pwm( 1000, 50) # 1 KHz, 50% state on
gpio.pwm_reset 

# put a OLED on I2C SDA/SCL, : work with seeedStudio OLED grovve

oled=OnionOled.new(0,0)
oled.write_at(0,0,"Hello world...")

```
Oled clock :

```ruby
########################################################################
#  oled : test oled
########################################################################
require_relative "onion-gpio"

def getMem()
 `free`.each_line {|line|
    next unless line=~ /^Mem:/
    mem=line.chomp.split(/\s+/)[3].to_i/1024
    return("FreeMem: #{mem} MB")
 }
 "?"
end

def getFlash()
 `df -h`.each_line {|line|
    next unless line=~ /^overlayfs:/
    mem=line.chomp.split(/\s+/)[3]
    return("FreeFlash: #{mem}")
 }
 "?"
end

oled=OnionOled.new(0,0)
oled.reset
oled.pos(0,0,ARGV.join(' ')) 
loop {
   oled.pos(10,5,Time.now.to_s.split(' ')[1])
   oled.pos(0,0,getMem())
   oled.pos(0,1,getFlash())
   sleep 1
}
```
![a photo](https://user-images.githubusercontent.com/27629/29748900-a89fcd00-8b20-11e7-8dee-249171d4ddd1.png)
