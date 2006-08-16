# session_test.rb
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
class SessionTest < Test::Unit::TestCase
  
  def setup

  end

  def test_create
    s = PT::Session.new
    assert_equal s.class , PT::Session
  end
  
  def test_renumber
    s = PT::Session.new
    s.add_track "A Track"
    s.add_track "B Track"
    s.add_track "C Track"
    s.tracks.slice(1)
    s.renumber_tracks_from(1)
    
    s.tracks[0].name == "A Track"
    s.tracks[1].name == "C Track"
    s.tracks[0].channel == 1
    s.tracks[1].channel == 2
    
  end
  
  def test_attributes
    s = PT::Session.new
    s.title = "Test Value"
    s.print_frames = true
    s.blend = 2.0
    
    assert_equal s.blend , 2.0
    assert_equal s.print_frames , true
    assert_equal s.title , "Test Value"
  end

end #class