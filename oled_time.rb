########################################################################
#  oled : test oled
########################################################################
require_relative "onion-gpio"

def getMem()
 `free`.each_line {|line|
    next unless line=~ /^Mem:/
    mem=line.chomp.split(/\s+/)[3].to_i/1024
    return("FreeMem:   #{mem} MB")
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
nb=0
loop {
   oled.pos(10,5,Time.now.to_s.split(' ')[1])
   if nb==0 || nb<60
     oled.pos(0,0,getMem())
     oled.pos(0,1,getFlash())
     nb=0
   else
     nb+=1
   end
   sleep 1
}
