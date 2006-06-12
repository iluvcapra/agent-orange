# track_test.rb
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

# Tests simple track operations
class TrackTest < Test::Unit::TestCase
  
  def setup
    @session = PT::Session.new
    @session.title = "TrackTest session"
    @session.time_code_format = "30 Frame"
    @session.time_format = :footage
  end
  
  def test_setters
    track = PT::Track.new @session
    
    track.name= "This new track"
    track.channel = 5
    
    assert_equal(track.name , "This new track")
    assert_equal(track.channel , 5)
  end

  def test_add_primitive_region
    track = PT::Track.new(@session)
    
    track.add_primitive_region('test 1',0,600)

    assert(track.regions.size == 1)
    assert_equal(track.regions[0].start,0)
    assert_equal(track.regions[0].finish,600)
  end

  def test_add_many_primitive_regions
    track = PT::Track.new(nil)
    
    track.add_primitive_region('test 1',0,1200)
    track.add_primitive_region('test 2',1500,2000)
    track.add_primitive_region('test 3',25_000,30_000)
    
    assert(track.regions.size == 3)
    assert_equal(track.regions[0].start,0)
    assert_equal(track.regions[0].finish,1200)    
    assert_equal(track.regions[1].start,1500)
    assert_equal(track.regions[1].finish,2000)
    assert_equal(track.regions[2].start,25_000)
    assert_equal(track.regions[2].finish,30_000)
  end
  
  def test_add_region
    track = PT::Track.new(@session)
    
    track.add_region('test A',"0+00","12+00")

    assert_equal(track.regions.size, 1)
    assert_equal(track.regions[0].start, 0)
    assert_equal(track.regions[0].finish, 12 * PT::Region.divs_per_foot)
  end
  
end #class