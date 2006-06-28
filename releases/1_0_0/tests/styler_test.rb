# styler_test.rb
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

require 'rubygems'
require 'test/unit'
$: << "lib/"
require 'pt/session'
require 'pt/track'
require 'pt/region'
require 'pdf_qs'

# Tests simple track operations
class StylerTest < Test::Unit::TestCase
  
  def setup
  end
  
  def test_styler_set
    style = Cuesheet::Styler.new

    style.default :size => 12
    style.title :face => "Times"
    style.title :size => 14
    style.title :italic => true
    style.title :bold => true

    assert_equal(style.default(:size) , 12)
    assert_equal(style.title(:face) , "Times")
    assert_equal(style.title(:size) , 14)
    assert_equal(style.title(:italic) , true)
    assert_equal(style.title(:bold) , true)
  end
  
  def test_style_default
    style = Cuesheet::Styler.new

    style.default :size => 14
    style.default :face => "Helvetica"
    style.title :size => 10
    
    assert_equal(style.title(:size), 10)
    assert_equal(style.title(:face), "Helvetica")
  end

  
end #class