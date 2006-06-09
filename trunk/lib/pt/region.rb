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
require 'pt/session'

module PT
  class Region

    attr_reader :track , :region_name
    attr_reader :start , :finish 
    attr_accessor :line_break
    
    def initialize(track)
      @track= track
      @region_name = "(blank)"
      @start = 0
      @finish = 1
      @line_break = "^"
    end
    
    def name=(str)
      @region_name = str
      if @asterisk_shade == false then
        @asterisk_shade = (@region_name[0,1] == "*")
      end
    end
    
    def name
      if session.shading == :asterisks then
        @region_name[0,1] == "*" ? @region_name[1,256] : @region_name
      else
        @region_name
      end
    end
    
    def shade?
      case session.shading
      when :all
        return true
      when :asterisks
        return @region_name[0,1] == "*"
      when :none
        return false
      end
    end
    
    def name_lines
      ret_ary = @line_break ? name.split(@line_break) : [ name ]
      ret_ary.shift if ret_ary.first == ''
      ret_ary
    end
    
    def reframe!
      if @start != @finish then 
        modulus = session.time_format == :footage ? divs_per_foot : divs_per_second
        self.start = @start - @start % modulus
        self.finish = @finish - (@finish % modulus) + modulus unless @finish % modulus == 0
      end #if
    end
    
    def start=(i)
      @start = i
      @track.impose! self
    end
    
    def finish=(i)
      @finish = i
      @track.impose! self
    end
    
    def start_time=(tc)
      self.start = str_to_tc(tc)
    end

    def finish_time=(tc)
      self.finish = str_to_tc(tc)
    end

    def start_time
      tc_to_str(@start)
    end

    def finish_time
      tc_to_str(@finish)    
    end
    
    def duration
      @finish - @start
    end
    
    def feet_only
      ! @track.session.print_frames
    end

    def session
      @track.session
    end
	
   private

    def divs_per_second
      600
    end

    def divs_per_foot
      divs_per_second * 2 / 3
    end

    def str_to_tc(str)
      if md = /(\d+)\+(\d+)/.match(str) then
        val =  md[1].to_i * divs_per_foot
        val += md[2].to_i * (divs_per_second / 24)
        session.time_format = :footage
      elsif md = /(\d+)\:(\d+)\:(\d+)[\:\;](\d+)/.match(str) then
        val = md[1].to_i * divs_per_second * 60 * 60
        val += md[2].to_i * divs_per_second * 60
        val += md[3].to_i * divs_per_second
        val += md[4].to_i * (divs_per_second / session.fps)
        session.time_format = :tc
      else
        val = 0
      end
      return val
    end

    def tc_to_str(divs)
      case session.time_format
      when :footage
        rem = divs % divs_per_foot
        feet = (divs - rem) / divs_per_foot
        fr = rem / (divs_per_second / 24)
        feet_only ? feet.to_s + "'" : "%i+%02i" % [ feet , fr ]
      when :tc
        rem = divs % (dph = divs_per_second * 60 * 60)
        hh  = (divs - rem) / dph ; divs -= dph * hh
        rem = divs % (dpm = divs_per_second * 60)
        mm  = (divs - rem) / dpm ; divs -= dpm * mm
        rem = divs % divs_per_second
        ss  = (divs - rem) / divs_per_second ; divs -= divs_per_second * ss
        ff  = divs / ( divs_per_second / session.fps )
        feet_only ? "%02i:%02i" % [mm , ss] : "%02i:%02i:%02i" % [mm , ss , ff]
      end
    end
  end
end #module