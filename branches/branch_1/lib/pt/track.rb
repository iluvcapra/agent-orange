# track.rb
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

require 'pt/region'

module PT
  class Track
    
    class RegionSequence < Array; end

    attr_reader :session
    attr_reader :regions
    attr_accessor :name
    attr_accessor :channel

    def initialize(s)
      @session = s
      @regions = []
      @name = "(blank)"
      @channel = 0
    end
    
    def create_region(&block)
      r= Region.new(self)
      block.call(r)
      @regions << r
      @regions.sort!
      r
    end


    def add_region(name = '(blank)' , start = '', finish = '')
      create_region do |r|
        r.name, r.start_time, r.finish_time = name , start , finish
      end
    end
    
    def add_primitive_region(name,start,finish)
      create_region do |r|
        r.name, r.start, r.finish = name , start , finish
      end
    end

    def reframe!
      @regions.each {|r| r.reframe! }
    end

    def update(region)
      impose! region
      @regions.sort!
    end

    def impose!(imposing_region)
      
      overwritten = @regions.delete_if do |region|
        region.start >= imposing_region.start && \
        region.finish <= imposing_region.finish && \
        region.object_id != imposing_region.object_id 
      end
      
      trim_tail = @regions.find do |region|
        region.finish > imposing_region.start && \
        region.start < imposing_region.start && \
        region.finish < imposing_region.finish
      end
      trim_tail.finish = imposing_region.start if trim_tail
      
      trim_head = @regions.find do |region|
        region.start < imposing_region.finish && \
        region.finish > imposing_region.finish && \
        region.start > imposing_region.start
      end
      trim_head.start = imposing_region.finish if trim_head
    end

    def blend!(duration = nil)
      dur = duration || @session.blend * Region.divs_per_second
      
       (@regions.size - 1).times do |i|
         first , second = @regions[i] , @regions[i.succ]
         first.finish = second.start if (second.start - first.finish) <= dur
       end
    end #def

    def delete_all_regions!
      @regions = []
    end

    def interpret_tagging!(duration = nil)
      legal_tags = [ "]" , "[" , "[[" , "]]" ,
                     "}" , "{" , "{{" , "}}" ,
                     ">" , "<" , "<<" , ">>" ,
                     "&" , "!" , "!!" ]
      
      open_tags = ["[" , "<" , "{"]
      
      blend! duration
      
      sequences = []
      last_in = -1
      @regions.each do |region|
        sequences << RegionSequence.new if region.start > last_in
        sequences.last << region
        last_in = region.finish
      end
      
      delete_all_regions!
      
      stick_open = false 
      new_region = nil
      
      sequences.each do |seq|
        unless stick_open then
          seq_start = seq.first.start
          new_region = nil 
        end
        
        tags_count = seq.inject(0) do |memo,region|
          (legal_tags.include? region.tag ) ? memo + 1 :  memo
        end
        
        seq.each do |region|
          clean_name , tag = region.clean_name , region.tag

          if legal_tags.include? tag then
            curly_start = (stick_open ? region.start : seq_start)

            case tag
              when "]" , "["
                new_region = add_primitive_region(clean_name , region.start , region.finish)
                
              when "]]" , "[["
                stick_open = true
                new_region = add_primitive_region(clean_name , region.start , region.finish)
                
              when "}" , "{"
                new_region = add_primitive_region(clean_name , curly_start ,region.finish)
                 
              when "}}" , "}}"
                stick_open = true
                new_region = add_primitive_region(clean_name , curly_start ,region.finish)                
              when ">" , "<"
                add_primitive_region("Fill" , seq_start , region.start) unless new_region
                new_region = add_primitive_region(clean_name , region.start , region.finish)
                
              when ">>" , "<<"
                stick_open = true
                add_primitive_region("Fill" , seq_start , region.start) unless new_region
                new_region = add_primitive_region(clean_name , region.start , region.finish)
                                
              when "&"
                if new_region then
                  new_region.name = (new_region.clean_name + " " + clean_name)
                  new_region.finish = region.finish
                else
                  new_region = add_primitive_region(clean_name , curly_start ,region.finish)                 
                end
              when "!"
                if stick_open then
                  stick_open = false
                  new_region.finish = region.start
                end
                
              when "!!"
                if stick_open then
                  stick_open = false
                  new_region.finish = region.finish
                end
            end
            seq_start = region.finish
          else
            if tags_count > 0 then
              if new_region then
                new_region.finish = region.finish
                seq_start = region.finish
              else
                
              end
            else
              if new_region then
                new_region.finish = region.finish
              else
                new_region = add_primitive_region(clean_name,region.start,region.finish)
              end
            end
          end
        end #seq.each |region|
      end # sequences.each
      
    end

    def scan_region_name(region)
        md = /(.*)-([^-]*)$/.match(region.name)
        return md[1] , md[2] if md
        return region.name , nil
    end
    
    
  end
end