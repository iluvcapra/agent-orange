require 'test/unit'
$: << "lib/"
require 'pt/session'
require 'pt/track'
require 'pt/region'

class BlendTest < Test::Unit::TestCase
  
  def test_proximity_blend
    track = PT::Track.new(nil)
    
    track.add_primitive_region('test 1',0,600)
    track.add_primitive_region('test 2',900,1100)
    
    track.blend!(600,false)
    
    assert(track.regions.size == 2)
    assert(track.regions[0].start == 0)
    assert(track.regions[0].finish == 900)
    assert(track.regions[1].start == 900)
    assert(track.regions[1].finish == 1100)
  end
  
  def test_proximity_no_blend
    track = PT::Track.new(nil)
    
    track.add_primitive_region('test 1',0,600)
    track.add_primitive_region('test 2',900,1100)
    
    track.blend!(100,false)
    
    assert(track.regions.size == 2)
    assert(track.regions[0].finish == 600)
    assert(track.regions[1].start == 900)
  end

  def test_tag_forces_no_blend
    track = PT::Track.new(nil)
    
    track.add_primitive_region('test 1',0,600)
    track.add_primitive_region('test 2-!',700,1000)
    track.add_primitive_region('test 3',1000,1300)
    track.add_primitive_region('test 4',1400,1800)
    track.add_primitive_region('test 5',5000,5300)
    track.add_primitive_region('test 6',5400,5800)
    
    track.blend!(300,true)
    
    assert_equal(track.regions.size , 6)
    assert_equal(track.regions[0].start,   0)
    assert_equal(track.regions[0].finish,  700)
    assert_equal(track.regions[1].start,   700)
    assert_equal(track.regions[1].finish,  1000)    
    assert_equal(track.regions[2].start,   1000)
    assert_equal(track.regions[2].finish,  1300) #shouldn't blend into next!
    assert_equal(track.regions[3].start,   1400)
    assert_equal(track.regions[3].finish,  1800)
    assert_equal(track.regions[4].start,   5000)
    assert_equal(track.regions[4].finish,  5400)    
    assert_equal(track.regions[5].start,   5400)
    assert_equal(track.regions[5].finish,  5800)
  end

  def test_tag_forces_blend
    track = PT::Track.new(nil)
    
    track.add_primitive_region('test 1-]]',0,   600)
    track.add_primitive_region('test 2',   700, 1000)
    track.add_primitive_region('test 3-!!',2000,3000)
    track.add_primitive_region('test 4',   4000,9000)

    track.blend!(200,true)
    
    assert_equal(track.regions.size , 4)
    assert_equal(track.regions[0].start,   0)
    assert_equal(track.regions[0].finish,  700)
    
    assert_equal(track.regions[1].start,   700)
    assert_equal(track.regions[1].finish,  2000)
     
    assert_equal(track.regions[2].start,   2000)
    assert_equal(track.regions[2].finish,  3000)
    
    assert_equal(track.regions[3].start,   4000)
    assert_equal(track.regions[3].finish,  9000)
  end

  
end #class