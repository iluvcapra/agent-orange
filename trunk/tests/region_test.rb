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
#  def test_decamelize
#    r = PT::Region.new
#    r.name = "ThisIsACamelizedName"
#    r.decamelize_name!
#
#    assert_equal(r.name, "This Is A Camelized Name")
#  end
  
  # test clean_name and clean_name=
  
end #class