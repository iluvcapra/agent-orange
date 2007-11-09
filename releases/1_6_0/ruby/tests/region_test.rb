# region_test.rb
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
require 'pt/region'

# Tests Region objects
class RegionTest < Test::Unit::TestCase
  def test_truth
    assert_equal 1,1
  end

  def test_decamelize
    r = PT::Region.new(nil)
    r.name = "ThisIsACamelizedName"
    r.decamelize_name!
    assert_equal(r.name, "This Is A Camelized Name")

    r.name = "ACamelizedNameWithALeadingA"
    r.decamelize_name!
    assert_equal(r.name, "A Camelized Name With A Leading A")

    r.name = "ANANGRYALLCAPSNAME"
    r.decamelize_name!
    assert_equal(r.name, "ANANGRYALLCAPSNAME")

#    r.name = "MIXEDCAPSAndCamelCase"
#    r.decamelize_name!
#    assert_equal(r.name, "MIXEDCAPS And Camel Case")

    r.name = "ThisIs1OtherCamelizedName"
    r.decamelize_name!
    assert_equal(r.name, "This Is 1 Other Camelized Name")

    r.name = "this is a Plain Name"
    r.decamelize_name!
    assert_equal(r.name, "this is a Plain Name")
  end
  
  def test_clean_name
    r = PT::Region.new(nil)
    r.name = "test-}"
    
    assert_equal(r.tag,"}")
    assert_equal(r.clean_name,"test")
    
    r.clean_name = "test 2"
    assert_equal(r.clean_name,"test 2")
    assert_equal(r.name,"test 2-}")
    assert_equal(r.tag,"}")
  end
  
end #class