# blend_test.rb
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

require 'test/unit'
$: << "lib/"
require 'pt/session'
require 'pt/track'
require 'pt/region'
require 'blender'

# The BlendTest class performs various tests which exercise the Track::Blender
# and make sure that the results of its action are appropriate.
#
# These work by instantiating a PT::Track, adding regions to it with known starts
# and finishes, and then calling a blend on it and seeing what comes out.
class BlendTest < Test::Unit::TestCase
  
  def setup
    @blender = Blender.new
  end
  
  # A test to make sure that regions that fall within the blend duration
  # are indeed blended.
  def test_proximity_blend
    track = PT::Track.new(nil)
    
    track.add_primitive_region('test 1',0,600)
    track.add_primitive_region('test 2',900,1100)
    
    @blender.blend_duration = 600
    test_track = @blender.blend_track(track)
    
    assert(test_track.regions.size == 2)
    assert(test_track.regions[0].start == 0)
    assert(test_track.regions[0].finish == 900)
    assert(test_track.regions[1].start == 900)
    assert(test_track.regions[1].finish == 1100)
  end
  
  # A test to make sure that regions outside of the blend duration
  # are NOT blended.
  def test_proximity_no_blend
    track = PT::Track.new(nil)
    
    track.add_primitive_region('test 1',0,600)
    track.add_primitive_region('test 2',900,1100)
    
    @blender.blend_duration = 100
    test_track = @blender.blend_track(track)
    
    assert(test_track.regions.size == 2)
    assert(test_track.regions[0].finish == 600)
    assert(test_track.regions[1].start == 900)
  end

  
end #class