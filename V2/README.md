V2 : Oion API using onion .so library
=======================================

How to use FFI with Fiddle
----------------------------
see file ```t.b``` :

```ruby
require 'fiddle'
require 'fiddle/import'

module LibOled
   extend Fiddle::Importer
   dlload '/usr/lib/libonionoledexp.so'
   extern 'int oledDriverInit()'
   extern 'int oledClear()'
   extern 'int oledSetCursor(int row, int column)'
   extern 'int oledWrite(char *msg)'
end

class Oled
  def initialize()
    LibOled.oledDriverInit()
  end  
  def clear()
    LibOled.oledClear()
  end
  def writeAt(x,y,text)
    LibOled.oledSetCursor(y,x)
    LibOled.oledWrite(text) 
  end
end

```


TODO
-----

* [X] : Oled
* [ ] : Gpio read/write DI/DO
* [ ] : Gpio pwm soft
* [ ] : gem
