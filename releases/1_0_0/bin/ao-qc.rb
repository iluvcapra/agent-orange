#!/usr/bin/env ruby

# == ao-qc - The Agent-Orange Cue-Cleaner
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

lib_path = File.dirname(__FILE__) + File::SEPARATOR + ".." + File::SEPARATOR + "lib"
$: << lib_path

APP_NAME = "ao-qc"
APP_AUTHOR = "Jamie Hardt"
APP_LONG_VERSION = "Version 0.1 2006-06-27"
APP_VERSION = 0.1


begin
  require 'pt/session'
  require 'pt/region'
  require 'pathname'
  require 'ostruct'
  require 'optparse'

  include PT
rescue
  $stderr.print "An error occurred while loading agent-orange libraries, \
    you may have an old version of the ruby interpreter.\n"
  exit 17001
end

cli_options = OpenStruct.new(:blend_duration => 1.0,
                             :interpret_tagging => true ,
                             :outfile => "-")

opts = OptionParser.new do |opts|
  
  opts.banner =  "Usage: ao-qc [OPTIONS] file"
  opts.separator "The Agent-Orange Cue-Cleaner, a script for pre-processing"
  opts.separator "text files formatted for cuesheeting."
  opts.separator ""
  
  opts.on("-b SECONDS","--blend-duration=SECONDS",Float,"Blend regions which occur",
                                                       "within this duration.") do |v|
    cli_options.blend_duration = v
  end

  opts.on("-i","--ignore-tagging", "Ignore tagging.") do
    cli_options.interpret_tagging = false
  end

  opt.on("-o" ,"--outfile" , "Output to file (default is STDOUT)") do |v|
    cli_options.outfile = v
  end

  opts.on_tail("-h","--help","Show this message.") do
    puts opts
    exit 0
  end                                                    
end #OptionParser

##$stderr.print "Starting cuesheet\n"
begin
  rest = opts.parse!($*)
rescue
  puts opts 
  exit 1
end

rest.each do |path|

  a_session = Session.new

  begin
    File.open(path,"r") do |file|
      a_session.read_file(file)
    end #File.open
  rescue SystemCallError
      $stderr.print "An error ocurred opening the file : " + $! + "\n"
      exit 4
  end
  
  a_session.blend = cli_options.blend_duration * Region.divs_per_second
  a_session.interpret_tagging! if cli_options.interpret_tagging
  
  if cli_options.outfile == "-" then
    puts a_session.to_text_export
  else
    File.open(cli_options.outfile,"w") do |wf|
      wf.write a_session.to_text_export
    end
  end
end

exit 0
