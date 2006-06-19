# region.rb
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
require 'pt/session'

require 'observer'

module PT
  class Region
    
    include Observable
    
    # The owning track of this region
    attr_reader :track
    
    # The raw name of this region.  The text of the region's name, without any processing for
    # line breaks, tagging, etc.
    attr_reader :raw_name
    
    # Integer values of the start and finish time of the region.  These are the
    # number of seconds for the start and finish, multiplied by Region::divs_per_second.
    attr_reader :start
    attr_reader :finish
    
    # The character that should signal a line break to a cuesheeting.
    attr_accessor :line_break
    
    # creates a new region, given a track to belong to.
    #
    # Regions are created with some explicit defaults.  Mainly, the default raw_name of a
    # region is <tt>(blank)</tt> and the default line break is a caret "^".
    # 
    # The region will be yielded to a block if one is given.
    def initialize(track)
      add_observer(@track) if @track= track
      @raw_name = "(blank)"
      @start = 0
      @finish = 1
      @line_break = "^"
      if block_given? then
        yield self
      end
    end
    
    # Comparison.  Regions that start before the +other+ are less than, etc.
    def <=>(other)
      @start <=> other.start
    end
    
    # At this time, this merely assigns +str+ to <tt>@raw_name</tt>.
    def name=(str)
      @raw_name = str
    end
    
    # At this time, this merely reads <tt>@raw_name</tt>.    
    def name
      @raw_name
    end
    
    # Returns the +raw_name+ of the region, minus and dash tagging.
    def clean_name
      md = tag_match_data
      md ? md[1] : @raw_name
    end
    
    # Returns the tag of this region, without its leading dash.
    def tag
      md = tag_match_data
      md ? md[2] : nil
    end
    
    # Sets the tag for this region, by either adding it to the end,
    # or adding it to the end of the clean name. Do *not* put a dash
    # at the beginning of +str+.  If you pass +nil+ or +false+ for 
    # +str+, the raw_name will be set to the clean name, effectively 
    # deleting any existing tag.
    def tag=(str)
      @raw_name = if str then
        clean_name + "-" + str
      else
        clean_name
      end
    end
    
    # Returns an array, essentially the region name split by the
    # +line_break+ string.
    def name_lines
      ret_ary = @line_break ? name.split(@line_break) : [ name ]
      ret_ary.shift if ret_ary.first == ''
      ret_ary
    end
    
    # This be deprecated.
    def reframe!
      if @start != @finish then 
        modulus = session.time_format == :footage ? Region.divs_per_foot : Region.divs_per_second
        self.start = @start - @start % modulus
        self.finish = @finish - (@finish % modulus) + modulus unless @finish % modulus == 0
      end #if
    end
    
    def start=(i)
      @start = i
      times_changed
    end
    
    def finish=(i)
      if i >= @start then
        @finish = i
        times_changed
      end
    end
    
    # Passing a string containing a timecode expression will set the start time of the region.
    # The region class attempts to identify the format of the string you pass; if it contains colons or
    # semicolons, it is recognized as timecode in the fps of the session which possesses this region.
    # If the string contains a plus sign, it is interpreted as a footage in 24fps.
    def start_time=(tc)
      self.start = str_to_tc(tc)
    end

    def finish_time=(tc)
      self.finish = str_to_tc(tc)
    end

    # Returns the start of this region as a timecode string, in the
    # format of the owning session.
    def start_time
      tc_to_str(@start)
    end
    
    # Returns the finish of this region as a timecode string, in the
    # format of the owning session.
    def finish_time
      tc_to_str(@finish)    
    end
    
    # Returns an Integer duration, finish - start.
    def duration
      @finish - @start
    end
    
    # Returns the durartion of this region as a timecode string, in the
    # format of the owning session.
    def duration_time
      tc_to_str(duration)
    end
    
    # Deprecated.
    def feet_only
      ! @track.session.print_frames
    end

    # A convenice for <tt>track.session</tt>
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
  	
    
  protected
    def tag_match_data # :nodoc:
      /(.*)-([^-]*)$/.match(@raw_name)
    end
    
    def times_changed
      changed; notify_observers self
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