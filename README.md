Presentation
============

Discovered Omega2+, OpenWrt with 128MB for 10€ , I try it with ruby lang.
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
* [ ] I2C
* [ ] develop acces to serial line
* [ ] configure the gpio : use  ```omega2-ctrl gpiomux```   for configure uart/i2c/spi/i2s/pwm

Feel free to collaborate to the project !


Ruby use on Omega2+
====================

no difficulties :

> ```opkg intall ruby```

> ```opkg install rubygems```

This represent 5MB on flash memory, at ```/usr/lib/ruby```.
```
~# du -s /usr/lib/ruby/*
5078    /usr/lib/ruby/2.4
156     /usr/lib/ruby/gems
5       /usr/lib/ruby/ruby2.4-bin
0       /usr/lib/ruby/site_ruby
0       /usr/lib/ruby/vendor_ruby
```

And at ruby/2.4 :
```
:~# du -s  /usr/lib/ruby/2.4/* | grep -v ".rb"
17      /usr/lib/ruby/2.4/bigdecimal
98      /usr/lib/ruby/2.4/cgi
4       /usr/lib/ruby/2.4/digest
32      /usr/lib/ruby/2.4/fiddle
1       /usr/lib/ruby/2.4/forwardable
31      /usr/lib/ruby/2.4/json
28      /usr/lib/ruby/2.4/matrix
730     /usr/lib/ruby/2.4/mipsel-linux-gnu
317     /usr/lib/ruby/2.4/net
7       /usr/lib/ruby/2.4/optparse
83      /usr/lib/ruby/2.4/psych
18      /usr/lib/ruby/2.4/racc
**1792    /usr/lib/ruby/2.4/rdoc**
825     /usr/lib/ruby/2.4/rubygems
106     /usr/lib/ruby/2.4/uri
9       /usr/lib/ruby/2.4/yaml
```

After installing python (12MB) and node.js (9MB), it remains 5MB free on the 32MB flash  ( ```/overlay``` ).



onion-gpio.rb
=============
Use sysfs for acces to gpio.

Duration: 3ms for writing one output line.

Use programs like fast-gpio, oled-exp an i2c-get for other acces.

**issues**

Access to /sys/class/gpio is locked by export/unexport file.
if several process/thread are accessing gpio, Exception while be raise.
DONE : if lock, unlock (!) and raise Exception
TODO : rescue n times on lock

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
[a photo](https://user-images.githubusercontent.com/27629/29748900-a89fcd00-8b20-11e7-8dee-249171d4ddd1.png)
