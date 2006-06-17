# pdf_test.rb
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
class TrackTest < Test::Unit::TestCase
  
  def setup
    testfile = "tagging_test_cases/in/1sec_blend_test.txt"
    
    @session = PT::Session.new
    File.open(testfile,"r") do |fp|
      @session.read_file(fp)
    end
  end
  
  def test_to_pdf
    qs = Cuesheet.new(@session)
    assert_nothing_raised do
      qs.to_pdf
    end
  end

  
end #class