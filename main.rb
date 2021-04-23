#! /usr/bin/env ruby
require 'opencv'
require 'flammarion'
include OpenCV
# Checking Command Arguments.
if ARGV.size() < 2 then
 puts "Usage: ruby main.rb [ path/to/file ] [ Rate of binarization ]"
 exit
end
if !File.exist?(ARGV[0]) then
 puts "No such file: #{ARGV[0]}"
 exit
end
# Converting an image to grayscale after importing it
gray = IplImage.load(ARGV[0]).BGR2GRAY
output = Flammarion::Engraving.new
# get image binary data
data = CvHistogram.new(1, [256], CV_HIST_ARRAY, [[0,255]]).calc_hist([gray])
luminance = Array.new(256, 0)
bit_sum = 0
256.times { |i|
 luminance[i] = data[i]
 bit_sum += data[i]
}
# show plot
output.plot(luminance, type:'bar')
output.wait_until_closed
# Binarization rate
border = bit_sum*ARGV[1].to_i/100.0.to_f
threshold = 0
256.times { |i|
 border -= luminance[255 - i]
 if border <= 0 then
 threshold = 255 - i
 break
 end
}
puts threshold
# generate image
p_tile = gray.threshold(threshold.to_i, 255, :binary)
GUI::Window.new('p_tile').show(p_tile)
GUI::wait_key
# Labeling
width   = p_tile.width
height  = p_tile.rows
mat = Array.new(width*height, 1)
lookup = []
new_label = 1
(width*height).times do |i|
    mat[i] = 0 if gray[i].to_ary[0].to_i < threshold
    upper_pixel = i/height > 0 ? mat[i - width] : 0
    lef_pixel = i%width > 0 ? mat[i - 1] : 0
    if mat[i] == 1 then
        if upper_pixel == 0 && lef_pixel == 0 then
            mat[i] = new_label
            new_label+=1
        end
        if upper_pixel != 0 && lef_pixel != 0 then
            mat[i] = upper_pixel < lef_pixel ? upper_pixel : lef_pixel
            lookup.push([lef_pixel, upper_pixel]) if upper_pixel < lef_pixel
            lookup.push([upper_pixel, lef_pixel]) if upper_pixel > lef_pixel
        end
        mat[i] = lef_pixel if upper_pixel == 0 && lef_pixel != 0
        mat[i] = upper_pixel if upper_pixel != 0 && lef_pixel == 0
    end
end
(lookup.sort{|a,b| b[1] <=> a[1]}).each do |i|
    mat.map!{|x| x==i[0] ? i[1] : x}
end
p mat.uniq.length - 1