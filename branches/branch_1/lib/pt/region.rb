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
        
    def <=>(other)
      @start <=> other.start
    end
    
    def initialize(track)
      @track= track
      @region_name = "(blank)"
      @start = 0
      @finish = 1
      @line_break = "^"
    end
    
    def name=(str)
      @region_name = str
    end
    
    def name
      @region_name
    end
    
    def tag
      md = tag_match_data
      md ? md[2] : nil
    end
    
    def tag=(str)
      md = tag_match_data
      @region_name = if str then
        md ? md[1] + "-" + str : @region_name + "-" + str
      else
        md[1]
      end
    end
    
    def tag_match_data
      /(.*)-([^-]*)$/.match(@region_name)
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
    
    def duration_time
      tc_to_str(duration)
    end
    
    def feet_only
      ! @track.session.print_frames
    end

    def session
      @track.session
    end
	
	class << self
	  def divs_per_second
      600
    end
	
	  def divs_per_foot
      divs_per_second * 2 / 3
    end
  end
	
   private
   
   
    def str_to_tc(str)
      divs_per_foot , divs_per_second = self.class.divs_per_foot , self.class.divs_per_second
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
      divs_per_foot , divs_per_second = self.class.divs_per_foot , self.class.divs_per_second
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