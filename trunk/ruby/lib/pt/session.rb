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
require 'pt/region'
require 'tag_interpreter'

module PT
  
  # The Session class is an entity which represents a "Session" in a Pro Tools user's
  # understanding of this term.
  #
  # At its core, a session is an ordered collection of tracks, and certain attributes
  # which are universal to the tracks, like a session name, a time code format, etc.
  class Session
    
    # The +title+ is the Session Title, usually the file name of the original session, 
    # minus any extension.
    attr_accessor :title
    
    # +tracks+ is an Enumerable data structure which yields each track in the order of
    # it's vertical screen placement.
    attr_reader   :tracks
    
    # If +print_frames+ evaluates to +false+, only feet or hh:mm:ss will be printed on
    # the sessions resulting cuesheet.  Frames will be printed in other cases.
    #
    # *Note*: This attribute should be moved to the +Cuesheet+ object at some point.
    attr_accessor :print_frames
    
    # +time_code_format+ is a string which can accept the values that would be present
    # in the "TIME CODE FORMAT:" record in a session export.  It gives the frame count
    # per second, and thus allows the absolute frame count of events to be calculated
    # from the time code in a text export (which otherwise would be ambiguous).
    #
    # A common value for this is '30 Frame' or '29.97 Frame'.  Clients of this
    # attribute must accept that it can hold any value that the "TIME CODE FORMAT:"
    # record can hold.
    attr_accessor :time_code_format
    
    # +time_format+ can hold one of two Symbols, +:footage+ or +:tc+.  This is set by
    # the +Region+ object when new regions are read from a text export, and the region
    # object consults this property when it must display its time.
    #
    # _This is deprecated and should be moved somewhere else_
    attr_accessor :time_format
    
    # +blend+ is a Numeric that is the blend duration; if the +start+ of a region, minus
    # the +finish+ of the region following it on a track is less than +blend+, the regions
    # will be blended together when +interpret_tagging!+ is called.
    #
    # _This is deprecated and should be moved_
    attr_accessor :blend
    
    def initialize
      @title = "New Session"
      @sample_rate , @bit_depth = 48000 , 16
      @time_code_format = "30 Frame"
      @tracks = []
      @print_frames = true
      @time_format = :footage
      @audio_file_count = 0
      @blend = 1.0 * Region.divs_per_second
    end
    
    # Returns every region in the session, as an +Array+, in no particular guaranteed
    # order.
    def audio_regions
      @tracks.inject([]) { |memo,trk| trk.regions + memo }
    end
    
    # Returns the frames-per-timecode-second of this session, based on the value of
    # +time_code_format+.  Values that may be returned by this presently are 30, 25, and 24.
    def fps
      case @time_code_format
        when /29|30/  ; 30
        when /25/     ; 25
        when /24|23/  ; 24
      end
    end
    
    # Changes the +channel+ attribute of each track in the session, going from first to last
    # in the session's +tracks+ array.  The argument +number+ may be a +Integer+ or +String+,
    # or any object that returns an appropriate value for +succ+ and +to_s+. 
    def renumber_tracks_from(number)
      @tracks.each do |track|
        track.channel = number
        number = number.succ
      end
    end
      
    # Calls +Track.reframe!+ on each track, and sets +print_frames+ to +false+.
    def reframe!
      @tracks.each {|t| t.reframe! }
      @print_frames = false
    end
    
    # Creates a new +TagInterpreter+ for each track in the session and applies them
    # to each track, one by one, using the +blend+ attribute.
    def interpret_tagging!
      begin
        tag_reader = TagInterpreter.new do |ti|
          ti.blender.blend_duration = @blend
        end
        new_tracks = @tracks.collect {|t| tag_reader.interpret_track(t) }
        @tracks = new_tracks
      rescue => e
        raise e , e.to_s + "\nTag interpreting failed for session : #{title}\n" + e.backtrace.join("\n")
      end
    end
    
    # Adds a new track to the session, with the name +name+ and with a default +channel+ value,
    # which is by default the track's index (from 1).  If +name+ is an empty string, the track's
    # name will be set to a concatenation of the letter "A" and the track's index (from 1).
    def add_track(name)
      t = Track.new(self)
      name != "" ? t.name = name : t.name = "A" + @tracks.size.succ.to_s
      t.channel = @tracks.size.succ.to_s
      @tracks << t
      t
    end
    
    # A convenience method, calls +decamlize_name!+ on each of +audio_regions+.
    def decamelize!
      audio_regions.each {|r| r.decamelize_name! }
    end
    
    # Reads a a +File+ or +IO+ object, +io+ and populates the session with the objects described
    # in the +io+.  The +io+ must contain text in the format of a Pro Tools text export, which is a
    # tab-delimited ASCII (or MacRoman) text file using either DOS, Unix or Mac OS line breaks,
    # depending on what version of Pro Tools exported the file.
    def read_file(io,line_ending = nil )
      curr_tr, curr_region, reading = nil , nil , false
      
      # We make +parse+ a little proc that splits a string into an array of stripped strings.
      parse = proc do |line| 
        line.split(%r/\t/).map{|c| c.strip}
      end
      
      # If the caller has specified a +line_ending+, use that, otherwise try to
      # autodetect.  The method for autodetection will fail if the first line of
      # the text export, the SESSION NAME: record, is longer than 80 characters.
      if line_ending then
        my_line_ending = line_ending
      else
        my_line_ending = if io.gets("\n").size < 80 then
            "\n"
          elsif io.rewind && io.gets("\r\n").size < 80 then
            "\r\n"
          else
            "\r"
          end
        # put us back at the head of the file, now that we know how to read it.
        io.rewind
      end
      
      status_index = nil
      
      io.each(my_line_ending) do |line| # for each line in the file
        row = parse[line]               # split it into cells
        case row[0]                     # if the first cell in the line is...
          when 'SESSION NAME:'
            self.title = row[1]         # read the title
          when 'TIME CODE FORMAT:'
            @time_code_format = row[1]  # read the TC format
          when 'SAMPLE RATE:'
            @sample_rate = row[1].to_f      # read sample rate
          when 'BIT DEPTH:'
            @bit_depth = row[1][0..1].to_i  # read bit depth, etc...
          when '# OF AUDIO FILES:'
            @audio_file_count = row[1].to_i
          when 'TRACK NAME:'
            curr_tr = add_track(row[1])     # create a new track, and put us in a state
                                            # for adding things to it
          when 'CHANNEL'
            reading = true if curr_tr && row[1] == 'EVENT' # put us in the +reading+ mode for
                                                           # the current track.
            status_index = row.find_index('STATE')
            
          when '1'                                         # if the region is on channel 1
            if reading then                                # and we're reading
              name = row[2].strip
              name = "(blank)" unless name
              if status_index
                
                r = curr_tr.add_region(name, row[3], row[4], row[status_index]) unless row[status_index] == 'Muted'
      
              else 
                r = curr_tr.add_region(name, row[3], row[4], 'Unmuted')
      
              end
            end
          when nil                            # if the line was blank
            curr_str , reading = nil , false  # put us out of track reading mode
        end #case
      end #each
    end #def
    
    # Generate an export of all the appropriate data from the +Session+ object, in
    # Pro Tools text export format, as a String, using Unix line endings by default.
    def to_text_export(line_ending = "\n")
      output = ""
      output << ["SESSION NAME:", @title ].join(9.chr) << line_ending # 9.chr is a tab
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
