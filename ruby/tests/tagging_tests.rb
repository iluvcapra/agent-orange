# tagging_tests.rb
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
($:).unshift "lib/"
require 'pt/session'
require 'pt/track'
require 'pt/region'

require 'tag_interpreter'

# This TestCase tests some simple tagging operations.  All of these tagging operations
# are *LAW* and any if your patches break any of these tests, you patch will not be
# applied.
#
# It is not recommended for you to add your own test cases to this TestCase; these
# are for foundational operations of tagging and if you find a particular tagging
# operation that doesn't come out the way you're expecting, contact Jamie and writeup
# a text import-export test for your full file.  If your scenario is particularly
# compelling Jamie will add it.
class TaggingTest < Test::Unit::TestCase

  def setup # :nodoc:
    @session = PT::Session.new
    @session.title = "TaggingTest"
    
    @tag_interpreter = TagInterpreter.new do |ti|
      ti.blender.blend_duration = 2.0
    end
    
  end
  
  # Test for untagged regions.
  #
  # Any sequence made up of untagged regions should be made into one region, with the name
  # of the first region.
  def test_untagged
    track = @session.add_track("Untagged")
    
    track.add_region("test 1" , "90+0", "95+0")
    track.add_region("test 2" , "95+0", "99+0")
    track.add_region("test 3" , "99+0", "110+0")
    
    track_result = @tag_interpreter.interpret_track(track)
    
    assert_equal(track_result.regions.size , 1)
    assert_equal(track_result.regions[0].clean_name , "test 1")
    assert_equal(track_result.regions[0].start  , 90 * PT::Region.divs_per_foot)
    assert_equal(track_result.regions[0].finish , 110 * PT::Region.divs_per_foot)
  end

  # Test for the closed-brace-tag *-}*.
  #
  # Definitively, a closed brace tag cause the region so tagged to start where it's
  # containing sequence starts.
  def test_brace_closed
    track = @session.add_track("Simple -}")
    
    track.add_region('test 1'  ,"9+0"  ,"12+0")
    track.add_region('test 2-}',"12+0" , "18+0")
    
    track_result = @tag_interpreter.interpret_track(track)
        
    assert_equal(track_result.regions.size, 1)
    assert_equal(track_result.regions[0].clean_name, "test 2")
    assert_equal(track_result.regions[0].start,    9 * PT::Region.divs_per_foot)
    assert_equal(track_result.regions[0].finish , 18 * PT::Region.divs_per_foot)
  end
  
  # Test for the closed-bracket-tag "-]".
  #
  # Definitively, a closed bracket tag causes the sequence of regions leading up to
  # a region so tagged to be omitted.
  def test_bracket_closed
    track = @session.add_track("Simple -]")
    
    track.add_region('test 1',   "100+0", "105+0")
    track.add_region('test 2-]', "105+0", "120+0")
      
    track_result = @tag_interpreter.interpret_track(track)
 
    assert_equal(track_result.regions.size , 1)
    assert_equal(track_result.regions[0].clean_name,   "test 2")
    assert_equal(track_result.regions[0].start,   105 * PT::Region.divs_per_foot)
    assert_equal(track_result.regions[0].finish,  120 * PT::Region.divs_per_foot)
  end
 
  # Test for the closed-angle-bracket-tag "->".
  #
  # Definitively, a closed angle bracket causes the sequence of regions leading up to the
  # region so tagged to be labeled "Fill".
  def test_angle_bracket_closed
    track = @session.add_track("Simple ->")
    
    track.add_region('test 1',   "30+0", "35+0")
    track.add_region('test 2->', "35+0", "40+0")
      
    track_result = @tag_interpreter.interpret_track(track)
 
    assert_equal(track_result.regions.size , 2)
    assert_equal(track_result.regions[0].clean_name,   "Fill")
    assert_equal(track_result.regions[0].start,   30 * PT::Region.divs_per_foot)
    assert_equal(track_result.regions[0].finish,  35 * PT::Region.divs_per_foot)
    assert_equal(track_result.regions[1].clean_name ,  "test 2")    
    assert_equal(track_result.regions[1].start,   35 * PT::Region.divs_per_foot)
    assert_equal(track_result.regions[1].finish,  40 * PT::Region.divs_per_foot)
  end

  # Test the open bracket tag "-["
  #
  # A region tagged with an open-bracket will start at the time of the region,
  # but will also *end* at the time of the *start* of the region, causing the
  # resulting region to have zero duration
  def test_bracket_open
    track = @session.add_track("Simple -[")
    
    track.add_region('test 1-[',   "45+0" , "51+0")
    
    track_result = @tag_interpreter.interpret_track(track)
    
    assert_equal(track_result.regions.size , 1)
    assert_equal(track_result.regions[0].clean_name,   "test 1")
    assert_equal(track_result.regions[0].start,   45 * PT::Region.divs_per_foot)
    assert_equal(track_result.regions[0].finish,  45 * PT::Region.divs_per_foot) 
  end
  
  # Test the ampersand tag "-&"
  # 
  # Within a sequence of regions, an ampersand causes the clean text of a second region 
  # to be concatenated with a space " " to the clean text of a first tagged region.  
  # The amperand-tagged region itself is omitted, and the first region is lengthened 
  # to cover the space occupied by her victim.
  def test_ampersand
    track = @session.add_track("Simple -&")
    
    track.add_region('test 1-]',   "45+0" , "51+0")
    track.add_region('test 2-&', "51+0" , "58+0")
    
    track_result = @tag_interpreter.interpret_track(track)
    
    assert_equal(track_result.regions.size , 1)
    assert_equal(track_result.regions[0].clean_name,   "test 1 test 2")
    assert_equal(track_result.regions[0].start,   45 * PT::Region.divs_per_foot)
    assert_equal(track_result.regions[0].finish,  58 * PT::Region.divs_per_foot) 
  end
  
  # Test of simple cue insertion with "-]"
  #
  # Using the "-]" in the middle of an audio sequence, when a host region precedes
  # it, will cause the first host region to end and a second to commence in the middle
  # of the sequence.
  def test_insert_cue
    track = @session.add_track("Insert cue with -]")
    
    track.add_region('test 1-]',  "100+0" , "105+0")
    track.add_region('test 2-]',  "105+0" , "110+0")
    
    track_result = @tag_interpreter.interpret_track(track)
    
    assert_equal(track_result.regions.size , 2)
    assert_equal(track_result.regions[0].clean_name , "test 1")
    assert_equal(track_result.regions[0].start ,  100 * PT::Region.divs_per_foot)
    assert_equal(track_result.regions[0].finish , 105 * PT::Region.divs_per_foot)
    assert_equal(track_result.regions[1].clean_name , "test 2")
    assert_equal(track_result.regions[1].start ,  105 * PT::Region.divs_per_foot)
    assert_equal(track_result.regions[1].finish , 110 * PT::Region.divs_per_foot)
  end
  
  # Test blend stop with "-!"
  #
  # A region tagged with "-!" will cause a region sequence to end at the leading edge of
  # the region.  The region tagged with the "-!" is omitted, and blending is not premitted
  # to occur across the gap.
  def test_blend_stop
    track = @session.add_track("Blend stop with -!")

    track.add_region('test 1-}',  "100+0" , "105+0")
    track.add_region('test 2-!',  "105+5" , "106+0")    
    track.add_region('test 2-]',  "106+0" , "110+0")
    
    track_result = @tag_interpreter.interpret_track(track)

    assert_equal(track_result.regions.size , 2)
    assert_equal(track_result.regions[0].clean_name , "test 1")
    assert_equal(track_result.regions[0].start ,  100 * PT::Region.divs_per_foot)
    assert_equal(track_result.regions[0].finish , 105 * PT::Region.divs_per_foot)
    assert_equal(track_result.regions[1].clean_name , "test 2")
    assert_equal(track_result.regions[1].start ,  106 * PT::Region.divs_per_foot)
    assert_equal(track_result.regions[1].finish , 110 * PT::Region.divs_per_foot)    
  end
  
  # Test of forced continued cue "-}}"
  #
  # A region tagged with a "-}}" will form an audio sequence with all regions following
  # it without regard for the distance between them, until a "-!!" or "-!" region is
  # encountered.
  def test_forced_continued_cue
    track = @session.add_track("Forced cue with -}}")
    
    track.add_region('test 1-}}',  "100+0" , "105+0")
    track.add_region('test 2-!!',  "130+0" , "180+0")
    
    track_result = @tag_interpreter.interpret_track(track)
    
    assert_equal(track_result.regions.size , 1)
    assert_equal(track_result.regions[0].clean_name , "test 1")
    assert_equal(track_result.regions[0].start ,  100 * PT::Region.divs_per_foot)
    assert_equal(track_result.regions[0].finish , 180 * PT::Region.divs_per_foot)
  end

   # Test of forced continued cue "-}}" with inserted cues
   #
   def test_forced_continued_cue_insertion
     track = @session.add_track("-}} with inserted cues")

     track.add_region('test 1-}}',  "100+0" , "105+0")
     track.add_region('test 2-]',   "120+0" , "180+0")
     track.add_region('test 3',     "300+0" , "320+0")
     track.add_region('test 4-]',   "360+0" , "400+0")
     track.add_region('test 5-!!',  "480+0" , "490+0")

     track_result = @tag_interpreter.interpret_track(track)

     assert_equal(track_result.regions.size , 3)
     assert_equal(track_result.regions[0].clean_name , "test 1")
     assert_equal(track_result.regions[0].start ,  100 * PT::Region.divs_per_foot)
     assert_equal(track_result.regions[0].finish , 120 * PT::Region.divs_per_foot)
     assert_equal(track_result.regions[1].clean_name , "test 2")
     assert_equal(track_result.regions[1].start ,  120 * PT::Region.divs_per_foot)
     assert_equal(track_result.regions[1].finish , 360 * PT::Region.divs_per_foot)
     assert_equal(track_result.regions[2].clean_name , "test 4")
     assert_equal(track_result.regions[2].start ,  360 * PT::Region.divs_per_foot)
     assert_equal(track_result.regions[2].finish , 490 * PT::Region.divs_per_foot)
   end

  
end #class