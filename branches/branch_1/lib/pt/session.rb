# session.rb
# Author:: Jamie Hardt
#
# This file is part of "agent-orange".
# 
# "agent-orange" is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# "agent-orange" is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with "agent-orange"; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

require 'pt/track'

module PT
  class Session
    
    attr_accessor :title
    attr_reader :tracks
    attr_accessor :print_frames
    attr_accessor :time_code_format
    attr_reader :fps
    attr_accessor :time_format
    attr_accessor :blend
    
    def initialize
      @title = "New Session"
      @sample_rate , @bit_depth = 48000 , 16
      @time_code_format = "30 Frame"
      @tracks = []
      @print_frames = true
      @time_format = :footage
      @audio_file_count = 0
      @blend = 1.0
    end
    
    def audio_regions
      @tracks.inject([]) { |memo,trk| trk.regions + memo }
    end
    
    def fps
      case @time_code_format
        when /29|30/  ; 30
        when /25/     ; 25
        when /24|23/  ; 24
      end
    end
    
    def reframe!
      @tracks.each {|t| t.reframe! }
      @print_frames = false
    end
    
    def interpret_tagging!
      @interprets_tagging = true
      @tracks.each {|t| t.interpret_tagging! }
    end

    def add_track(name)
      t = Track.new(self)
      name != "" ? t.name = name : t.name = "A" + @tracks.size.succ.to_s
      t.channel = @tracks.size.succ.to_s
      @tracks << t
      t
    end

    def read_file(io,line_ending = nil )
      curr_tr, curr_region, reading = nil , nil , false

      parse = proc do |line| 
        line.split(%r/\t/).map{|c| c.strip}
      end
      
      if line_ending then
        my_line_ending = line_ending
      else
        my_line_ending = if io.gets("\n").size < 60 then
            "\n"
          elsif io.rewind && io.gets("\r\n").size < 60 then
            "\r\n"
          else
            "\r"
          end
        io.rewind
      end
      
      io.each(my_line_ending) do |line|
        row = parse[line]
        case row[0]
          when 'SESSION NAME:'
            self.title = row[1]
          when 'TIME CODE FORMAT:'
            @time_code_format = row[1]    
          when 'SAMPLE RATE:'
            @sample_rate = row[1].to_f
          when 'BIT DEPTH:'
            @bit_depth = row[1][0..1].to_i
          when '# OF AUDIO FILES:'
            @audio_file_count = row[1].to_i
          when 'TRACK NAME:'
            curr_tr = add_track(row[1])
          when 'CHANNEL'
            reading = true if curr_tr && row[1] == 'EVENT' 
          when '1'
            if reading then
              name = row[2].strip
              name = "(blank)" unless name
              r = curr_tr.add_region(name, row[3], row[4])
            end
          when nil
            curr_str , reading = nil , false
        end #case
      end #each
    end #def
    
    def to_text_export(line_ending = "\n")
      output = ""
      output << ["SESSION NAME:", @title ].join(9.chr) << line_ending
      output << ["SAMPLE RATE:" , "%.6f" % @sample_rate   ].join(9.chr) << line_ending
      output << ["BIT DEPTH:", "%i-bit" % @bit_depth.to_i ].join(9.chr) << line_ending
      output << ["TIME CODE FORMAT:",@time_code_format    ].join(9.chr) << line_ending
      output << ["# OF AUDIO TRACKS:",@tracks.size].join(9.chr) << line_ending
      output << ["# OF AUDIO REGIONS:",audio_regions.size ].join(9.chr) << line_ending
      output << ["# OF AUDIO FILES:", @audio_file_count].join(9.chr) << line_ending
      output << line_ending << line_ending
      
      if @tracks then
        output << "T R A C K  L I S T I N G" << line_ending
        @tracks.each do |track|
          output << ["TRACK NAME:" , track.name ].join(9.chr) << line_ending
          output << ["USER DELAY:" , "0 Samples" ].join(9.chr) << line_ending        
          output << ["CHANNEL","EVENT","REGION NAME","START TIME","END TIME","DURATION" ].join(9.chr) << line_ending 
          track.regions.each_with_index do |region,i|
            output << ["1","#{i+1}",region.name,region.start_time,region.finish_time,region.duration_time].join(9.chr)
            output << line_ending
          end
          output << line_ending << line_ending
        end
      end #if
      
      output
    end
    
  end #class Session
end #Module
