# tag_interpreter.rb
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


require 'blender'

require 'pt/track'
require 'pt/session'
require 'pt/region'

class TagInterpreter
  
  class RegionSequence < Array
    
    def tagged_regions_into(track)
      legal_tags = [ "]" , "[" , "[[" , "]]" ,
                     "}" , "{" , "{{" , "}}" ,
                     ">" , "<" , "<<" , ">>" ,
                     "&" , "!" , "!!" ]
      
      seq_start = first.start
      new_region = nil
      
      tags_count = inject(0) do |memo,region|
        (legal_tags.include? region.tag ) ? memo + 1 :  memo
      end
      
      each do |region|
        clean_name , tag = region.clean_name , region.tag

        if legal_tags.include? tag then
          curly_start = seq_start

          case tag
            when "]" , "]]" , "[["
              new_region = track.add_primitive_region(clean_name , region.start , region.finish)
              
            when "["
              new_region = track.add_primitive_region(clean_name , region.start , region.start)
              
            when "}" ,  "}}" , "}}"
              new_region = track.add_primitive_region(clean_name , curly_start , region.finish)
  
            when "{"
              new_region = track.add_primitive_region(clean_name , curly_start , curly_start)
  
            when ">", ">>" , "<<"
              track.add_primitive_region("Fill" , seq_start , region.start) unless new_region
              new_region = track.add_primitive_region(clean_name , region.start , region.finish)
            
            when "<" 
              track.add_primitive_region("Fill" , seq_start , region.start) unless new_region
              new_region = track.add_primitive_region(clean_name , region.start , region.start)              
                                 
            when "&"
              if new_region then
                new_region.name = (new_region.clean_name + " " + clean_name)
                new_region.finish = region.finish
              else
                new_region = track.add_primitive_region(clean_name , curly_start ,region.finish)
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
              new_region = track.add_primitive_region(clean_name,region.start,region.finish)
            end
          end
        end
      end #each |region|
    end #def
    
    
  end
  
  attr_reader :blender
  
  def initialize(&block)
    @blender = Blender.new
    block.call(self) if block
    return self
  end
  
  def blend_with_tags(track)
      hold_open_tags = ["[[","]]","{{" , "}}" , ">>" , "<<"]

      stick_open = false
      @blender.test_before_blend do |first,second|
        may_blend = true
        if first.tag == "!" then
          may_blend , stick_open = false , false
        end
        if second.tag == "!!" then
          stick_open = false
          second.tag = nil
          first.finish = second.start
        end
        if hold_open_tags.include?(first.tag) || stick_open then
          stick_open = true
          first.finish = second.start
        end
        may_blend
      end

      blended_track = @blender.blend_track(track)

      blended_track.regions.delete_if do |r|
        r.tag == "!"
      end
      blended_track
  end
  
  def interpret_track(track) # :returns: new_track
    open_tags = ["[" , "<" , "{"]
    
    blended_track = blend_with_tags(track)
    
    sequences = []
    last_in = -1
    blended_track.regions.each do |region|
      sequences << RegionSequence.new if region.start > last_in
      sequences.last << region
      last_in = region.finish
    end
    
    return_track = track.dup
    return_track.delete_all_regions!
       
    sequences.each do |seq|
        seq.tagged_regions_into(return_track)
    end # sequences.each
    
    return return_track
  end #def
  
  
end #class