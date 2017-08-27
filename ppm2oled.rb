#!/usr/bin/ruby
###########################################################################
# convert a monochorme BPM raster file to binary data file for OLED display
#   out format:
#     binary data for 128x64 OED Dislay (tested for SSD1308)
#       used by command > oled draw filename
# Usage
#   > ruby binary_file_bitmap_converter.rb filename-in.ppm filename-out.bin
#
# PPM file format:
#   Use Image Magik for convert a raster image to PPM format
#
#-------------------------------------------------------------------------
#
#  PPM Format :
#   L0:P6
#   L1:128 64
#   L2:1
#   L3:<binary-data> : 3 bytes by pixel, row by row, col by col, RGB in binary, 0..255 each
#
###########################################################################

raise("Usage: ruby #{$0} fileinput.PPM fileoutput.BIN") if ARGV.size!=2

File.open(ARGV[0],"rb") {|f|
  $magick=f.gets.chomp       
  $nbcols,$nbrows=f.gets.chomp.scan(/\d+/).map {|v| v.to_i}
  $maxgrey=f.gets.chomp.to_i
  $data=f.read($nbcols*$nbrows*3).unpack("C*")
}

$str= "Magik: %s, nbrow: %d, nbcols: %d, maxgrey: %d" % [$magick,$nbcols,$nbrows,$maxgrey]

raise("unvalide amgick number: nat a PPM file") if $magick!="P6"
raise("Not at raster of 128x64 pixels") if $nbrows!=64 || $nbcols!=128
raise("Number of color should be 1 : #{$maxgrey}") if $maxgrey!=1
raise("data size has wrong value : #{$data.size} / #{$nbcols*$nbrows*3}") if $data.size != $nbcols*$nbrows*3


pos=0
data=[]
$nbrows.times {|r| data << [] ;$nbcols.times {|c| data.last << ($data[pos]>0 ? 255 : 0) ; pos+=3 } }

alcd=Array.new($nbcols*$nbrows/8)
(0...$nbrows).step(8) {|r| $nbcols.times {|c| 
 lcd=(0...8).inject(0) {|v,b|  m=((data[r+b][c] & 1) << b) ; v|m }
 index   = (r * $nbcols)/8 + c
 alcd[index]=lcd
}}

File.open(ARGV[1],"w") {|f| f.write(alcd.map {|v| "%02x" % v}.join('')) }

