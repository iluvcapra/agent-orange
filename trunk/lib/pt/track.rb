# This file is part of "agent-orange".
# 
# "qs" is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# "qs" is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with "qs"; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

module PT
  class Track

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

    def add_region(name = '(blank)' , start = 0, finish = 0)
      r = Region.new(self)
      r.name, r.start_time, r.finish_time = name , start , finish
      @regions << r
      r
    end
    
    def add_primative_region(name,start,finish)
      r = Region.new(self)
      r.name, r.start, r.finish = name , start , finish
      @regions << r
      r
    end

    def reframe!
      @regions.each {|r| r.reframe! }
    end

    def impose!(imposing_region)
      overwritten = @regions.delete_if do |region|
        region.start >= imposing_region.start && \
        region.finish <= imposing_region.finish && \
        region.object_id != imposing_region.object_id 
      end
      
      trim_tail = @regions.find do |region|
        region.finish > imposing_region.start && \
        region.start < imposing_region.start
      end
      trim_tail.finish = imposing_region.start if trim_tail
      
      trim_head = @regions.find do |region|
        region.start < imposing_region.finish && \
        region.finish > imposing_region.finish
      end
      trim_head.start = imposing_region.finish if trim_head
      
    end
    
    def interpret_tagging!
      legal_tags = [ "]" , "[" , "[[" , "]]" ,
                     "}" , "{" , "{{" , "}}" ,
                     ">" , "<" , "<<" , ">>" ,
                     "&" , "!" , "!!" ]
      
      sequences = []
      my_regions = @regions.dup
      @regions = []
      blend_duration = @session.blend * 600
      last_o = 0 - blend_duration - 1
    
      my_regions.each do |region |
        if region.start - last_o > blend_duration then
          sequences << []
        end
        last_o = region.finish
        (sequences.last).last.finish = region.start if sequences.last.last
        sequences.last << region
      end
      
      stick_open = false 
      new_region = nil
      
      sequences.each do |seq|
        unless stick_open then
          seq_start = seq.first.start
          new_region = nil 
        end
        
        one_tagged = seq.inject(false) do |memo,region|
          clean_name , tag = scan_region_name(region)
          legal_tags.include? tag or memo
        end
        
        seq.each do |region|
          clean_name , tag = scan_region_name(region)
          if legal_tags.include? tag then
            curly_start = (stick_open ? region.start : seq_start)
            case tag
              when "]" , "["
                new_region = add_primative_region(clean_name , region.start , region.finish)
               
              when "]]" , "[["
                stick_open = true
                new_region = add_primative_region(clean_name , region.start , region.finish)
                
              when "}" , "{"
                new_region = add_primative_region(clean_name , curly_start ,region.finish)
                 
              when "}}" , "}}"
                stick_open = true
                new_region = add_primative_region(clean_name , curly_start ,region.finish)                
              when ">" , "<"
                add_primative_region("Fill" , seq_start , region.start) unless new_region
                new_region = add_primative_region(clean_name , region.start , region.finish)
                
              when ">>" , "<<"
                stick_open = true
                add_primative_region("Fill" , seq_start , region.start) unless new_region
                new_region = add_primative_region(clean_name , region.start , region.finish)
                                
              when "&"
                if new_region then
                  new_region.name = (new_region.name + " " + clean_name)
                  new_region.finish = region.finish
                else
                  new_region = add_primative_region(clean_name , curly_start ,region.finish)                 
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
            if one_tagged then
              if new_region then
                new_region.finish = region.finish
                seq_start = region.finish
              else
                
              end
            else
              if new_region then
                new_region.finish = region.finish
              else
                new_region = add_primative_region(clean_name,region.start,region.finish)
              end
            end
          end
        end
      end # sequences.each       
    end

    def scan_region_name(region)
#       md = /(.*)(-\]|-\[|-\}|-\{|-<|->|-\]\]|-\[\[|-\}\}|-\{\{|-<<|->>|-&|-!|-!!)$/.match(region.name)
        md = /(.*)-([^-]*)$/.match(region.name)
        return md[1] , md[2] if md
        return region.name , nil
    end
    
    
  end
end