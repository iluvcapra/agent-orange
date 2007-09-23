#!/usr/bin/env ruby
#
#  Created by Jamie Hardt on 2006-06-29.
#  Copyright (c) 2006. All rights reserved.

# == ao-info - The Agent Orange Text Reader
# Author:: Jamie Hardt
#
# This tool is built to very quickly read information from a text export, and little more.

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

class SessionNotRecognizedError < RuntimeError; end

ARGV.each do |path|
  begin
    File.open(path,"r") do |fp|

      parse = proc do |line| 
        line.split(%r/\t/).map{|c| c.strip}
      end
      
      my_line_ending = if fp.gets("\n").size < 60 then
          "\n"
        elsif fp.rewind && fp.gets("\r\n").size < 60 then
          "\r\n"
        else
          "\r"
        end
      fp.rewind
      
      test , session_name = parse[fp.readline(my_line_ending)]
      raise SessionNotRecognizedError unless test == "SESSION NAME:"
      
      3.times { fp.readline(my_line_ending) } 
      test , track_count = parse[fp.readline(my_line_ending)]
      raise SessionNotRecognizedError unless test == "# OF AUDIO TRACKS:"
      
      track_names = []
      while (not fp.eof?) do
        cols = parse[fp.readline(my_line_ending)]
        track_names << cols[1] if cols[0] == "TRACK NAME:"
      end
      
      puts   "--------------------------------------------------"
      puts   "Session Name         : " + session_name
      puts   "Number of Tracks     : " + track_count
      puts   "Track Names          > "
      track_names.each {|name| puts "                     > " + name}
    end #File.open
  rescue SystemCallError
    $stderr.print "There was an error reading a file : #{$!}\n"
    exit 4
  rescue SessionNotRecognizedError
    $stderr.print "Error: This file does not appear to be a properly-formatted text export : #{path}\n"
    exit 1
  end
end

exit 0