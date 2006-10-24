# tagging_test_cases.rb
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
require 'string_helper.rb'


# == Tagging Test Cases
#
# This unit test runs all of the text files in +tagging_test_cases+/+in+ through the
# tag interpretation machinery and compares them to files with the same name in
# +tagging_test_cases+/+out+.  If the files match, the test is passed, otherwise, the
# test fails.
#
# If you want to test a particular tagging situation to make sure agent-orange handles
# the tagging process properly, you use Pro Tools to export a session that's been tagged
# a particular way.  You put this file in the +tagging_test_cases+/+in+ folder.  Then, make
# a copy of this file and edit it with a text editor until the output looks exactly like the
# output ot Session#interpret_tagging! should.  Put this file in +tagging_test_cases+/+out+.

class TaggingTestCases < Test::Unit::TestCase

  def setup
    @infile_dir =  Dir.pwd / "tagging_test_cases" / "in"
    @outfile_dir = Dir.pwd / "tagging_test_cases" / "out"
    @test_outfile_dir = Dir.pwd / "tagging_test_cases" / "test"
    Dir.mkdir @test_outfile_dir
    
    @test_files = []
    Dir.new(@infile_dir).each do | file |
      @test_files << file if (File.file?(file) && /\.txt$/.match(file))
    end
  end
  
  def teardown
    @test_files.each { |old| File.unlink(@test_outfile_dir / old) }
    Dir.rmdir @test_outfile_dir
  end
  
  def test_tagging_cases
    @test_files.each do |file|    
      infile_path , outfile_path , testfile_path = \
        @infile_dir / file , @outfile_dir / file, @test_outfile_dir / file
      
     File.open(infile_path,"r") do |infile|

       session = PT::Session.new
       session.read_file(infile)
       session.interpret_tagging!
       
       File.open(testfile_path , "w+") do |testfile|
         testfile.write session.to_text_export
       end
       
       diff = `diff -u #{testfile_path} #{outfile_path}`

       unless diff == nil then
         flunk "Tagging test case for #{infile_path} failed :\n" + diff
       end
     end
              
    end
    
  end

end #class