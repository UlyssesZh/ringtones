#!/usr/bin/env ruby

require 'fileutils'
require 'open3'

OUT_DIR = 'build'
FileUtils.mkdir_p OUT_DIR

SOUNDFONT_FILENAME = ENV['SOUNDFONT_FILENAME'] || '/usr/share/soundfonts/FluidR3_GM2-2.sf2'
SAMPLING_RATE = 44100
HALF_LENGTH = SAMPLING_RATE / 2 # 0.5 seconds
OUTPUT_FORMATS = %w[wav ogg]

def write name, code
	alda = IO.popen %W[alda -v 0 export], 'r+b'
	timidity =  IO.popen %W[timidity - -idq -A100 -s #{SAMPLING_RATE} -Or1sl -x soundfont\s"#{File.expand_path SOUNDFONT_FILENAME}" -o -], 'r+b'
	ffmpeg = IO.popen %W[ffmpeg -v -8 -f s16le -ar #{SAMPLING_RATE} -ac 2 -i pipe:0 -y] + OUTPUT_FORMATS.map { File.join OUT_DIR, "#{name}.#{_1}" }, 'wb'

	alda.puts '(tempo! 240) guitar: (volume 100) (quant 10000) ' + code
	alda.close_write
	IO.copy_stream alda, timidity
	alda.close
	(HALF_LENGTH * 2 * 2).times do |i| # HALF_LENGTH*2 is total sample count, another *2 is for 2 channels
		i /= 2 # 2 channels
		amp = timidity.read(2).unpack1('s<') / (0xffff * 0.5) # signed 16-bit little-endian
		amp *= 2 - i / HALF_LENGTH.to_f if i >= HALF_LENGTH # fading out in the latter half
		amp = (amp * 0xffff * 0.5).round
		ffmpeg.write [amp].pack('s<')
	end
	timidity.close
	ffmpeg.close
end

write '6', 'g-'
write '42', 'e16 d'
write '255', 'd12 f f'
write '1108', 'd-16 r d- c a-'
