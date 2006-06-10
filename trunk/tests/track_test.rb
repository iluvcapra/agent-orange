require 'test/unit'
$: << "lib/"
require 'pt/session'
require 'pt/track'
require 'pt/region'

class TrackTest < Test::Unit::TestCase
  

  def test_add_primitive_region
    track = PT::Track.new(nil)
    
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
  
end #class