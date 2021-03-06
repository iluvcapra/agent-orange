#!/usr/bin/env ruby
# == agent-orange - The Agent Orange Cuesheet Generator
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

($:).unshift File.dirname(__FILE__) + File::SEPARATOR + ".." + File::SEPARATOR + "lib"
($:).unshift File.dirname(__FILE__) + File::SEPARATOR + ".." + File::SEPARATOR + "lib/ext"

APP_NAME = "agent-orange"
APP_AUTHOR = "Jamie Hardt"
APP_LONG_VERSION = "Version 1.6.0"
APP_VERSION = "1.6.0"

begin
  
  begin
    require 'rubygems'
  rescue LoadError
    $stderr.print "RubyGems not found, skipping."
  end
  
  require 'string_helper.rb'
  require 'pdf_qs'
  require 'pt/session'
  require 'pt/region'
  require 'blender'
  require 'tag_interpreter'

  require 'pathname'
  require 'ostruct'
  require 'optparse'

  include PT
rescue
  $stderr.print "An error occurred while loading agent-orange libraries, \
    you may have an old version of the ruby interpreter.\n"
  exit 17001
end
PAPER_SIZES = {'LETTER' => 'LETTER',
               'TABLOID' => [ 0 , 0 , 792 , 1224 ],
               'LEGAL' => 'LEGAL'}

OptionParser.accept(Range,/(\d+)-(\d+)/) do |r,start,fin|
  Range.new(start.to_i,fin.to_i)
end

options = OpenStruct.new( :paper => 'LETTER',
                          :given_title => nil,
                          :given_strip_count => nil,
                          :given_outfile => nil,
                          :interpret_tags => true,
                          :verbose => false,
                          :print_frames => false,
                          :line_endings => nil ,
                          :frames => false ,
                          :info => false,
                          :blend => 1,
                          :shading => true,
                          :watermark => nil,
                          :exclude_list => [],
                          :renumber_from => nil,
                          :print_track_numbers => true,
                          :decamelize => false,
                          :hide_muted_regions => false)

opts = OptionParser.new do |opts|
  
  opts.banner =  "Usage: #{$0} [OPTIONS] file"
  opts.separator "A Ruby script for generating cuesheets from text files."
  opts.separator ""
  
  opts.on("-p PAPER" , 
          "--paper=PAPER" , 
          "Paper size (TABLOID, LETTER, and LEGAL are supported , default is LETTER)") do |v|
    options.paper = v if v == 'TABLOID' or v == 'LETTER' or v == 'LEGAL'
  end
  
  opts.on( "-e TRACK_POS", "--exclude=TRACK_POS", 
           "Exclude a track at TRACK_POS (leftmost",
           "track is track 0) from the cuesheet.",
           "Call multiple times to exclude many.") do |v|
    options.exclude_list << v.to_i         
  end
  
  opts.on("-r STRING", "--renumber-from=STRING",
            "Renumber tracks, starting from the",
            "leftmost track, with STRING.  STRING",
            "will be incremented intelligently",
            "for each track.  Renumbering happens",
            "after all tracks have been excluded",
            "with -e.") do |v|
     options.renumber_from = v         
  end
  
  opts.on("-0",
            "Do not print track numbers, print",
            "track names only.") do
    options.print_track_numbers = false
  end
  
  opts.on("-D",
            "Enable DeCamelizer.  White space will",
            "be added to camelized region names.") do
    options.decamelize = true
  end

    opts.on("-m",
            "Hide muted regions.  Text exports from Pro Tools ",
            "10.2 or greater indicate wether clips are muted or not.") do
        options.hide_muted_regions = true
    end
    
  opts.on("-f" , 
          "--frames", 
          "Print times with frames") do |v|
    options.frames = true
  end
  
  opts.on("-s NUM" , 
          "--strips=NUM", 
          "Number of strips per page (default 8 for letter, 16 for tabloid)") do |v|
    options.given_strip_count = v.to_i
  end
  
  opts.on( "--shade-nothing", 
          "Turn of region shading") do |v|
    options.shading = false
  end
  
  opts.on( "--cue-font-size=NUM",
           "Set Cue Font size") do |v|
    options.cue_font_size = v.to_i         
  end
  
  opts.on("-t TITLE" , 
          "--title=TITLE" , 
          "Title to print on top (default is session name)") do |v|
    options.given_title = v
  end

  opts.on("-b BLEND" , 
          "--blend=BLEND" ,
          Float, 
          "Blend duration (in seconds; only applies when interpreting tagging)") do |v|
    options.blend = v.to_f
  end

  opts.on("-o FILENAME" , 
          "--outfile=FILENAME" , 
          "Output file to FILENAME.") do |v|
    options.given_outfile = v
  end

  opts.on("-l LINEFEED" , 
          "--line-endings=LINEFEED" , 
          "Specify the linefeed (CR, LF, or CRLF; automatic is default).") do |v|
    case v
    when 'CR'
        options.line_endings = "\r"
    when 'CRLF'
        options.line_endings = "\r\n"
    when 'LF'
        options.line_endings = "\n"
    end
  end

  opts.on("--verbose","Output status while running.") do
    options.verbose = true
  end

#  opts.on("-x","--info","Print information about the session and then exit.") do
#        options.info = true
#  end

  opts.on("-i" , "--ignore-tags", 
          "Ignore 'tagging'") do |v|
    options.interpret_tags = false
  end

  opts.on("-h","--help","-?","Show this message") do
    puts opts
    exit 1
  end
  opts.on("-v" , "--version", 
          "Show version") do
    puts "#{APP_NAME} - #{APP_LONG_VERSION}\n"
    exit
  end
  
  opts.separator ""
  opts.separator "By default, cuesheet outputs PDFs to the current working"
  opts.separator "directory, with file names matching the session names in put."
end

begin
  rest = opts.parse!($*)
rescue
  puts opts 
  exit 1
end

files = rest

options.strip_count = if options.given_strip_count then
                        options.given_strip_count
                      else
                        case options.paper
                         when 'LETTER'; 8
                         when 'TABLOID'; 16
                         when 'LEGAL'; 12
                        end
                      end

files.each do |file|
  $stderr.print "Reading file : #{file}...\n" if options.verbose
  the_session = Session.new

  if file == nil then
    $stderr.print "No file was specified for input.\n"
    puts opts
    exit 1
  end

  begin
    File.open(file,"rb") do |f|
      $stderr.print "Parsing input file...\n" if options.verbose
      the_session.read_file(f,options.line_endings)
    end
  rescue SystemCallError
    $stderr.print "An error ocurred opening the file : " + $! + "\n"
    exit 1
  end
  
    options.exclude_list.each do |excl_num|
      the_session.tracks[excl_num] = nil
    end
    
    the_session.tracks.compact!
    
    the_session.renumber_tracks_from(options.renumber_from) if options.renumber_from
    
    the_session.blend = options.blend * Region.divs_per_second
    the_session.title = options.given_title if options.given_title
    the_session.decamelize! if options.decamelize
    $stderr.print "Interpreting Tags...\n" if options.verbose
    the_session.interpret_tagging! if options.interpret_tags
    the_session.reframe! unless options.frames
    
    
    if options.given_outfile == nil then
      file_to_open = Dir.getwd / Pathname.new(file).basename(".txt") + ".pdf"
    else
      file_to_open = options.given_outfile
    end

    begin
      file_to_open = file_to_open + ".pdf" if file_to_open[-4,4] != ".pdf"
      File.open(file_to_open,"w") do |outfile|
        cuesheet = Cuesheet.new(the_session) do |q|
          q.paper = PAPER_SIZES[options.paper]
          q.strips_per_page = options.strip_count
          q.styles.regions(:shading => options.shading)
          q.print_track_numbers = options.print_track_numbers
          q.hide_muted_regions = options.hide_muted_regions
        end
        $stderr.print "Writing PDF \"#{File.basename(file_to_open)}\"...\n" if options.verbose
        pdf = cuesheet.to_pdf
        outfile.write pdf.render
      end
    rescue SystemCallError
      $stderr.print "An error occurred writing to the file " + 
        " '#{options.given_outfile}' : "+ $! +"\n"
      exit 1
    end
     $stderr.print "Finished with #{File.basename(file_to_open)}.\n" if options.verbose
  end
 
#end

exit 0