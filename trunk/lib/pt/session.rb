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

require 'csv'
require 'pt/track'

module PT
  class Session
    
    attr_accessor :title
    attr_reader :tracks
    attr_accessor :print_frames
    attr_reader :fps
    attr_accessor :time_format
    attr_accessor :blend
    attr_accessor :shading
    attr_accessor :cue_font_size
    attr_accessor :proportional
    attr_accessor :watermark
    attr_accessor :interprets_tagging
    attr_accessor :min_closed_cue_length
    
    def initialize
      @title = "New Session"
      @tracks = []
      @print_frames = true
      @fps = 24
      @time_format = :footage
      @blend = 1.0
      @shading = :all # :none | :asterisks | :all
      @cue_font_size = 10
      @proportional = true
      @watermark = nil
      @min_closed_cue_length = 600
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
          #$stderr.print "Reading name as #{row[1]}\n"
        when 'TIME CODE FORMAT:'
          @fps =  case row[1]
                    when /29|30/  ; 30
                    when /25/     ; 25
                    when /24|23/  ; 24
                  end
          #$stderr.print "Reading frame count as #{@fps}\n"        
        when 'TRACK NAME:'
          curr_tr = add_track(row[1])
          #$stderr.print "Reading track named #{row[1]}\n"        
        when 'CHANNEL'
          reading = true if curr_tr && row[1] == 'EVENT' 
          #$stderr.print "Channel detected for #{curr_tr.name}\n"
        when '1'
          if reading then
            name = row[2].strip
            name = "(blank)" unless name
            r = curr_tr.add_region(name, row[3], row[4])
            #$stderr.print "- Reading region #{name} at #{row[3]} - #{r.start_time}\n"
          end
        when nil
          curr_str , reading = nil , false
        end
      end
    end
  
    def display_tracks
      @tracks
    end

    def display_regions
      display_tracks.inject([]) {|all , track| all + track.regions}
    end

    def time_font_size
      13
    end

    def finish_time_font_size
      @cue_font_size
    end
  
    def paper_format
      #'LETTER' 
      [ 0 , 0 , 792 , 1224 ] #tabloid
    end
  
    def paper_orientation
      :landscape
    end
  
    def strips_per_page
      16
    end
  end
end #Module
