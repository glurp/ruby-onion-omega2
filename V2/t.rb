require 'fiddle'
require 'fiddle/import'

module LibOled
   extend Fiddle::Importer
   dlload '/usr/lib/libonionoledexp.so'
   extern 'int oledDriverInit()'
   extern 'int oledClear()'
   extern 'int _oledSendCommand(int command)'
   extern 'int _oledSendData(int data)'

   extern 'int oledSetCursor(int row, int column)'
   extern 'int oledSetCursorByPixel(int row, int pixel)'
   extern 'int oledWriteChar(char c)'
   extern 'int oledWrite(char *msg)'
   extern 'int oledWriteByte(int byte)'
   extern 'int oledScroll(int direction, int scrollSpeed, int startPage, int stopPage)'
   extern 'int oledScrollStop()'
   extern 'int oledReadLcdFile (char* file, uint8_t *buffer)'
   extern 'int oledDraw (uint8_t *buffer, int bytes);'
   #extern 'int '
   #extern 'int '
   #extern 'int '
   #extern 'int '
   #extern 'int '
   #extern 'int '
   #extern 'int '
   #extern 'int '
   #extern 'int '
   #extern 'int '

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
    #text.each_byte {|c| LibOled.oledWriteChar(c) }
  end
  def scroll(direction,speed,page0,page1)
    LibOled.oledScroll(direction,speed,page0,page1)
  end
  def scroll_stop()
    LibOled.oledScrollStop();
  end
 def drawFile(filename)
  content=File.read(filename)
  buffer= [content].pack("2H*")
  LibOled.oledDraw(buffer,buffer.size );
 end
end

oled=Oled.new
oled.clear()
oled.writeAt(0,0,'ABCDEFGH')
oled.writeAt(0,1,'abcde')
oled.scroll(0,100,0,10)
sleep 0.5
oled.scroll_stop
oled.drawFile("../oled.bin")

