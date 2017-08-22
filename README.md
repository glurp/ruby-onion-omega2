Presentation
============

Discovered Omega2+, OpenWrt with 128MB for 10€ , I try it with
ruby lang.

**TODO:**
* [x] develop a gpio library for digital input/output access
* [ ] develop a pwm library
* [ ] develop acces to serial line

**Plan:**
* V1 : develop this material without C librairie : use sysfs and some Onion exec fast-gpio ...)
* V2 : link to onionlib shared library via FFI, for provide same API as V1, but faster
* V3 : make a ionion  mruby executable with all io included :)

Curently V1 is started.

Ruby use on Omega2+
====================

no difficulties :

> ```opkg intall ruby```

> ```opkg install rubygems```

This represent 5MB on flash memory, at ```/usr/lib/ruby```.

after installing python and node.js, it remains 5MB free on /overlay.



onion-gpio.rb
=============
use sysfs for acces to gpio.

Duration: 3ms for writing one output line.

**issues**

Access to /sys/class/gpio is locked by export/unexport file.
if several process/thread are accessing gpio, Exception while be raise.
DONE : if lock, unlock (!) and raise Exception
TODO : rescue n times on lock

Example
=======

```ruby
require_relative 'ionion-gpio.rb'

gpio=OnionGpio.new( 3 , false)
gpio.setOutputDirection()
100.times { |i| gpio.setValue(i%2) ; sleep 0.1}

```

