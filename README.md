Presentation
============

Discovered Omega2+, OpenWrt with 128MB for 10€ , I try it with
ruby lang.

**TODO:**
* [x] develop a gpio library for digital input/output access
* [ ] develop a pwm library
* [ ] develop acces to serial line

**Plan:**
* V1 : develop this material without C librairie : use sysfs and some Onion exec (```fast-gpio``` ...)
* V2 : link to onionlib shared library via FFI, for provide same API as V1, but faster
* V3 : make a onion-mruby executable with all V2 io included :-)

Curently V1 is started.

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
this give 6% CPU, for the process (top visualisation)
