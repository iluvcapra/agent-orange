# blender.rb
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
require 'pt/track'

# A blender can manipulate a track and blend its regions.  It also provides for callbacks to be run as it is
# doing its job.
class Blender
  
  # Blend duration, in divs
  attr_accessor :blend_duration
  
  def initialize(&block)
    @blend_duration = PT::Region.divs_per_second
    @test_before_blend = nil
    block.call(self) if block
    return self
  end
  
  # Provide a track, and a blended track will be returned
  def blend_track(in_track)
    dur = @blend_duration
    track = in_track.dup
#    $stderr.print "Blending #{in_track.name}\n"
#    $stderr.print "|#   | Name                              | Start  | Finish | Total #\n"
    (track.regions.size).times do |i| 
      first , second = track.regions[i] , track.regions[i.succ]
      if first && second then
#        $stderr.print "|%-4s|%-35s|%8s|%8s|%4s\n" % [i.to_s,first.name[0..34], first.start_time,first.finish_time,track.regions.size.to_s] 
        may_blend = true
        may_blend = @test_before_blend.call(first,second) if @test_before_blend
        first.finish = second.start if (second.start - first.finish) <= dur && may_blend
      end #while
    end #times
     return track
  end #def
  
  def test_before_blend(&block)
    @test_before_blend = block if block.arity == 2
  end
end #class