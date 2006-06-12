# tagging_test_cases.rb
# Author:: Jamie Hardt

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



class TaggingTestCases < Test::Unit::TestCase

  def setup
    @infile_dir =  Dir.pwd + "/tagging_test_cases/in/"
    @outfile_dir = Dir.pwd + "/tagging_test_cases/out/"
  end
  
  def test_tagging_cases
    Dir.new(@infile_dir).each do |file|
      next unless (File.file?(@infile_dir + file))
      
      File.open(@infile_dir + file,"r") do |infile|

        session = PT::Session.new
        session.read_file(infile)
        session.interpret_tagging!
        
        File.open(@outfile_dir + file,"r") do |outfile|
          assert_equal(outfile.read,
            session.to_text_export, 
            "#{file} (#{session.title}) failed testing.")
        end 
      end
    end
    
  end

end #class