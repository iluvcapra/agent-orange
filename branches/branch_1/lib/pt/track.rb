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
    
    class Blender
      attr_accessor :blend_duration
      attr_accessor :interpret_tags
      attr_reader :regions
      
      BLEND_TAGS = ["]]",">>","}}"]
      
      def initialize(region_array)
        @regions = region_array
        if block_given? then
          yield self
        end
      end
      
      def blend!
        @blend_duration_memo = nil
        @blend_tag_active = false
        (@regions.size - 1).times do |i|
          first , second = @regions[i] , @regions[i.succ]
          first.finish = second.start if should_blend?(first,second)
          read_tags(first,second) if @interpret_tags
        end
        @regions
      end
      
    private
      
      def should_blend?(first,second)
        if @interpret_tags then
          closeness_forces_blend?(first,second) or tag_forces_blend?(first,second)
        else
          closeness_forces_blend?(first,second)
        end
      end
      
      def closeness_forces_blend?(first,second)
        second.start - first.finish < @blend_duration
      end
      
      def tag_forces_blend?(first,second)
          @blend_tag_active = true if BLEND_TAGS.include?(first.tag)
          @blend_tag_active
      end
      
      def read_tags(first,second)
        if first.tag && first.tag == "!" then
          @blend_tag_active = false 
          @blend_duration_memo = @blend_duration
          @blend_duration = 0
        elsif first.finish < second.start && @blend_duration_memo then
          @blend_duration = @blend_duration_memo
          @blend_duration_memo = nil
        end
        @blend_tag_active = false if second.tag && second.tag == "!!"
      end
      
    end


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
    
    def add_primitive_region(name,start,finish)
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

    def blend!(duration = nil, interpret_tags = true)

      b = Blender.new(@regions) do |blender|
        blender.blend_duration = duration || @session.blend * Region.divs_per_second
        blender.interpret_tags = interpret_tags
      end
      
      b.blend!
      
    end #def

    def interpret_tagging!
      legal_tags = [ "]" , "[" , "[[" , "]]" ,
                     "}" , "{" , "{{" , "}}" ,
                     ">" , "<" , "<<" , ">>" ,
                     "&" , "!" , "!!" ]
      
      open_tags = ["[" , "<" , "{"]
      
      blend! nil , true
      
      sequences = []
      
       ##FIXME!
      stick_open = false 
      new_region = nil
      
      sequences.each do |seq|
        unless stick_open then
          seq_start = seq.first.start
          new_region = nil 
        end
        
        tags_count = seq.inject(0) do |memo,region|
          clean_name , tag = scan_region_name(region)
          (legal_tags.include? tag ) ? memo + 1 :  memo
        end
        
        seq.each do |region|
          clean_name , tag = scan_region_name(region)

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
                  new_region.name = (new_region.name + " " + clean_name)
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