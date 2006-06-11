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

require 'pdf/writer' 

module PT
  class Session #print-related stuff
    attr_accessor :cue_font_size
    attr_accessor :proportional
    attr_accessor :watermark
    attr_accessor :shading
    
    def init_for_printing
      @shading = :all # :none | :asterisks | :all
      @cue_font_size = 10
      @proportional = true
      @watermark = nil
    end
    
    def display_tracks
      @tracks
    end

    def display_regions
      display_tracks.inject([]) {|all , track| all + track.regions}
    end

  end #class

  class Region
    def shade?
      case session.shading
      when :all
        return true
      when :asterisks
        return @region_name[0,1] == "*"
      when :none
        return false
      end
    end
  end 

end #module

class Cuesheet

  class Styler
    STYLES = [ :default , :title , :region_name , :time , :finish_time , :page_number ]
    STYLE_ATTRIBUTES = [ :face , :size , :bold , :italic ]

    def initialize
      @attributes = {}
      STYLES.each do |field| 
        @attributes[field] = {}
      end
      @attributes[:default] = { :face => "Helvetica" , 
                                :size => 12 , 
                                :bold => false , 
                                :italic => false}
    end

    def method_missing(sym, arg)
      if @attributes.has_key? sym then
        if arg.class == Hash then
          arg.each do |k,v|
           @attributes[sym][ k ] = v if STYLE_ATTRIBUTES.include?(k)
          end #do
        elsif arg.class == Symbol then
          return @attributes[sym][arg] || @attributes[:default][arg]
        end
      end #if
    end #def

  end #class


  attr_accessor :session
  attr_accessor :paper
  attr_accessor :strips_per_page
  attr_accessor :min_closed_cue_length
  attr_accessor :paper_orientation



  def initialize(s)
    @session = s
    @styler = Styler.new
    @time_font_size = 13
    @finish_time_font_size = 11
    @paper_orientation = :landscape
    @min_closed_cue_length = 600
    if block_given? then
      yield self
    end
  end

  def styles
    if block_given? then
      yield @styler
    end
    @styler
  end

  def to_pdf
    pdf_for_session(@session,@paper,@strips_per_page)
  end

  def pdf_for_session(s_obj , paper, strips_per_page)
    p = PDF::Writer.new(:paper => paper, 
          :orientation => @paper_orientation 
          )
        
    #$stderr.print "Starting PDF generation.\n"
  
    # Some overall dimensions
    p.select_font "Helvetica" , "MacRomanEncoding"

    header_size = 14 #title font size

    strip_width = p.margin_width / strips_per_page

    strip_header_font_size = 12
    strip_header_height = strip_header_font_size * 3
    channel_header_font_size = 9
    channel_header_height = 12 #

    cue_font_size = s_obj.cue_font_size
  
    grid_top = p.absolute_top_margin - (p.font_height(header_size))
    grid_bottom = p.absolute_bottom_margin
  
    cue_top = grid_top - (channel_header_height + strip_header_height)
  
    bracket_stroke_width = 2
  
    #$stderr.print "PDF DIMENSIONAL CHARACTERISTICS\n"
  
    #DRAW WATERMARK (IF FILE GIVEN)
  
    if s_obj.watermark then 
      p.open_object do | wm |
        image_height , image_width = 150 , 400
        #image_height , image_width = (p.page_height * 2 / 3) , (p.page_width * 2 / 3)
        y = (p.absolute_top_margin) / 2 + (image_height / 2)
        x = (p.absolute_right_margin / 2) - (image_width / 2)
        File.open(s_obj.watermark,"r") do |fd|
          p.add_image_from_file(fd,x,y,image_width,image_height)
        end
        p.close_object
        p.add_object( wm , :all_pages )
      end
    end#if
  
    # DRAW TITLE AT TOP OF EACH PAGE
    p.open_object do |header|
      t = s_obj.title #title text   
      p.save_state
      p.stroke_color! Color::RGB::Black
      p.stroke_style! PDF::Writer::StrokeStyle::DEFAULT
      w = p.text_width( t , header_size )
      x , y = p.left_margin , p.absolute_top_margin
      p.add_text(x , y , t , header_size)
  
      if (false) then
        x , w = p.absolute_left_margin , p.absolute_right_margin
        y -= (p.font_height(header_size) + 7.2 )
        p.line( x , y , w , y ).stroke
      end

      p.restore_state
      p.close_object
      p.add_object(header, :all_pages)
    end
  
    # DRAW STRIP GRID WITH HEADER BOXES ON EACH PAGE 
    p.open_object do |grid|
      p.save_state
      p.stroke_color! Color::RGB::Black
      p.stroke_style! PDF::Writer::StrokeStyle.new(1) # grid style

      strips_per_page.succ.times do |i|
        x = i * strip_width + p.absolute_left_margin
        y = grid_top
        h = grid_bottom
        p.line( x , y , x , h ).stroke
      end
 
      x1 , x2 = p.absolute_left_margin , p.absolute_right_margin
      y1 , y2 = grid_top , grid_bottom
      p.line( x1 , y1,  x2  , y1).stroke
      p.line( x1 , y2 , x2  , y2).stroke
    
      y1 = grid_top - strip_header_height
      p.line(x1 , y1 , x2 - 1 , y1).stroke
    
      p.stroke_style! PDF::Writer::StrokeStyle.new(2)
      y1 = grid_top - strip_header_height - channel_header_height
      p.line(x1 , y1 , x2 - 1, y1).stroke
    
      p.restore_state
      p.close_object
      p.add_object(grid , :all_pages)
    end
  
  
    #paginate
  
    #$stderr.print "Starting strip pagination.\n"
  
    # Break the strips down so into groups that appear on one page
    strip_pages , all_strip_pages = [] , s_obj.display_tracks
    pages , rem = *(all_strip_pages.size.divmod strips_per_page)
    pages += 1 if rem > 0
  
    pages.times do |i|
      strip_pages << all_strip_pages.slice(strips_per_page * i,strips_per_page)
    end
    #$stderr.print "Pages wide : #{strip_pages.size}\n"
  
    all_regions = s_obj.display_regions
  
    # == GENERATE TIME INDEXES ==
    # A time index must exist for every start and finish on the cuesheet
    # We assign a particular vertical position to every time index
    time_indexes = all_regions.inject([]) do |memo,region|
     memo << region.start ; memo << region.finish
    end
    time_indexes = time_indexes.uniq.sort
    ind_length = time_indexes.size
    #$stderr.print "Total time indexes : #{ind_length}\n"
  
    # == GENERATE TOPLINES ==
    # toplines holds an array of integers which indicate the vertical
    # position of each time index.  e.g. toplines[n] holds an integer
    # which is the number of points time_indexes[n] is displaced from
    # the TOP of the first page.
    #
    # The time_space_factor controls the minimum offset between two
    # adjacent time indexes.  Thus, 
    #               if toplines[n] == a certain value y, then
    #                  toplines[n+1] >= (y + time_space_factor)
    # Whether it is greater than, or merely equal to, depends on how
    # much space the regions at toplines[n] need to draw their names,
    # as we shall see....

    time_space_factor = @time_font_size
    toplines = Array.new
  
  
    ind_length.times {|i| toplines[i] = i * time_space_factor}
  
    #$stderr.print "Start time pagination.\n"
    proportion_finish_idx = nil
    time_indexes.each_with_index do |time,idx|
    
      # CALCULATE TOPLINE VALUES
      # At this point we calculate the displacement of each time_index
      # It's important to say that this y-displacement is *not* going
      # to be the actual y-dipsplacement, and the value here is not
      # used explicitly to position elements on a page.  We generate
      # these values as a sort of "dry run", and we use them to
      # calculate the relative displacements of time indexes to each
      # other.  Read on to see how....
    
      # first, if this printout will be proportional, we should nudge down
      # this start so that it will begin in a proportional location relative
      # to other regions.
      if s_obj.proportional && idx > 0 && proportion_finish_idx then
        y_displacement_from_previous = (toplines[idx] - toplines[idx - 1])
        previous_start_time = time_indexes[idx - 1]
        previous_finish_time = time_indexes[proportion_finish_idx]
        previous_start_y = toplines[idx - 1]
        previous_finish_y = toplines[proportion_finish_idx]
        ticks_per_point = (previous_finish_time - previous_start_time).to_f / (previous_finish_y - previous_start_y).to_f
        start_displacement = (time - previous_start_time).to_f / ticks_per_point
        if start_displacement > y_displacement_from_previous then
          (idx..(ind_length-1)).each {|i| toplines[i] += (start_displacement.to_i)}
        end
        proportion_finish_idx = nil
      end
    
      regions = all_regions.find_all {|r| r.start == time}
      regions.sort! {|a,b| a.finish <=> b.finish }
      regions.each do |region|
        # FOR EACH REGION THAT STARTS HERE...
      
        #$stderr.print "Indexing #{region.name} on #{region.track.name}\n"
      
        # get the index of its finish, since we'll have to move it down
        # the sheet in order to make room for this region's name
        finish_idx = time_indexes.index(region.finish)
      
        # if the region finishes where is starts, we should consider the
        # we really want to work with the next time_index down
        finish_idx += 1 if region.start == region.finish && time_indexes[finish_idx+1]
    
        # current_height is the amount of space we currently have 
        # set aside for this cue, figured as the difference between
        # the displacement of the start and the finish
        current_height = toplines[finish_idx] - toplines[idx]
      
        # We calculate the needed height to draw this region
        needed_height = cue_height(p,s_obj,region,strip_width)
 
        # if the difference in y-displacement between the start
        # and finish is less than the needed height...
        if current_height < needed_height then
          # we calcualte how much height we have to add...
          height_to_gain = needed_height - current_height
          # and we displace the toplines for the finish, and all following
          # time-indexes so that they still appear after this one.
          (finish_idx..(ind_length-1)).each {|i| toplines[i] += height_to_gain}
        end
      
        # if this is the shortest region of the set, save it as the
        # proportion finish_index
        if proportion_finish_idx then
          (proportion_finish_idx = [finish_idx , proportion_finish_idx].min)
        elsif s_obj.proportional then
          proportion_finish_idx = finish_idx
        end
      end #regions.each


    end #time_indexes.each_with_index
  
    #toplines contains absolute y's.  We want these to be widths.
    ind_length.times do |i|
      if toplines[i+1] then
        toplines[i] = toplines[i+1] - toplines[i]
      else
        # This is a safe bet
        toplines[i] = @finish_time_font_size
      end
      #$stderr.print "line width for row index #{i} at #{time_indexes[i]} is #{toplines[i]}\n"
    end
  
    index_lines = time_indexes.zip toplines
  
    remaining_space = cue_top - grid_bottom
    this_row_topline = cue_top
    extra_pad_at_bottom = 30
    remaining_space -= extra_pad_at_bottom
  
    #$stderr.print "Starting to apply lines into pages.\n"
  
    row_pages = []  
    row_pages << []
    this_remaining_space = remaining_space
    index_lines.each do |line|
      time , height = *line
      if this_remaining_space < height then
        row_pages << []
        regions_passing_here = all_regions.find_all do |r|
          (r.start < time and r.finish > time) or r.finish == time
        end
        this_row_topline = cue_top
        this_remaining_space = remaining_space
        top_padding = \
         (regions_passing_here.collect {|r| cue_height(p,s_obj,r,strip_width) }).max
        if top_padding then
          this_row_topline -= top_padding 
          this_remaining_space -= top_padding
        end
      end
      row_pages.last << [time , height , this_row_topline]
      this_remaining_space -= height
      this_row_topline -= height
    end
  
  
    #$stderr.print "Starting rendering.\n"
    row_pages.each_with_index do |row_page , page_index|
      # a row_page is an array of sheet_rows spanning a 
      # number of individual paper leaves 
      strip_pages.each_with_index do |pg , leaf_index|
        # a strip_page is an array of strips that appear
        # on a single leaf
      
        # page number
        p.add_text_wrap( p.absolute_right_margin - 300, 
          grid_top + 5, 300, 
          "Page <b>#{page_index.succ}#{(leaf_index+65).chr}</b> of " +
          "#{row_pages.size}#{(strip_pages.size+64).chr}" , 
          cue_font_size,:right)
      
        pg.each_with_index do |strip, i|
          # each strip
          row_start  = row_page.first[0]
          row_finish = row_page.last[0]

          strip_x = i * strip_width + p.absolute_left_margin
          bracket_x = strip_x + 6
          bracket_x2 = bracket_x + 10
        
          time_x = strip_x + 2         #******
          time_width = strip_width - (2)
          name_x = strip_x + 10                 #******
          name_width = strip_width - (8)
        
          bracket_start_y_offset = 4
          time_start_y_offset = 8 + bracket_start_y_offset
        
          #strip header
          y = grid_top - 2 - strip_header_font_size
          size = strip_header_font_size
          if i = strip.name.index("^") then
          	strip_header = strip.name[0,i]
          	rest = strip.name[i+1,strip.name.size - i]
          else
          	strip_header = strip.name
          end
          extra = p.add_text_wrap(strip_x+ 3,y,strip_width- 6,strip_header  ,size,:center )
          rest = extra if extra != ""
          y = y - (strip_header_font_size + 2)
          p.add_text_wrap(strip_x,y,strip_width,rest,size,:center ) if rest
        
          #channel_header
          size = channel_header_font_size
          y = grid_top - strip_header_height - channel_header_height + 3
          p.add_text_wrap(strip_x+ 3,y,strip_width - 6,strip.channel,size,:center)
        
          p.stroke_style! PDF::Writer::StrokeStyle.new(bracket_stroke_width)
        
          dont_finish_here = {}
          am_finishing_here = {}
          strip.regions.each {|r| dont_finish_here[r.start] = true; am_finishing_here[r.finish] = true }
        
        
          runthru = strip.regions.find do |r| 
            r.start < row_start and r.finish > row_finish
          end
        
          if runthru then
            #$stderr.print "Drawing \"#{runthru.name}\" as a runthru.\n"    
            y1 , y2 = cue_top , grid_bottom
          
            if runthru.shade? then
              p.save_state
              poly_points = [ [ bracket_x , y1 ], 
                              [ bracket_x , y2 ] , 
                              [ strip_x + strip_width , y2] , 
                              [ strip_x + strip_width , y1]]
              p.stroke_style! PDF::Writer::StrokeStyle.new( 0 )
              p.fill_color(Color::RGB.from_fraction( 0.95, 0.95, 0.95 ))
              p.polygon(poly_points).fill
              p.restore_state
            end
          
            p.line(bracket_x , y1 , bracket_x , y2).stroke
            text = runthru.name
            y1 -= cue_font_size  
            draw_cue_name(p , name_x , y1 , runthru , name_width , cue_font_size)
          else
            jumpin = strip.regions.find do |r|
              (r.start < row_start) and (r.finish >= row_start) and (r.finish <= row_finish) 
            end
          
            if jumpin then
              #$stderr.print "Drawing \"#{jumpin.name}\" as a jumpin.\n"
              this_finish_row = row_page.find {|a_pg| a_pg[0] == jumpin.finish}
              y1 , y2 = cue_top , this_finish_row[2] + @finish_time_font_size
              if (dont_finish_here[jumpin.finish] == true) then
                y2 -= @finish_time_font_size
              else
                y2 -= (@finish_time_font_size/2 + this_finish_row[1])
              end
  
              if jumpin.shade? then
                p.save_state
                poly_points = [ [ bracket_x , y1 ], 
                                [ bracket_x , y2 ] , 
                                [ strip_x + strip_width , y2] , 
                                [ strip_x + strip_width , y1 ]]
                p.stroke_style! PDF::Writer::StrokeStyle.new( 0 )
                p.fill_color(Color::RGB.from_fraction( 0.95, 0.95, 0.95 ))
                p.polygon(poly_points).fill
                p.restore_state
              end
 
              p.line(bracket_x , y1  , bracket_x , y2).stroke           
              #p.line(bracket_x , y2 , bracket_x+5 , y2).stroke #test!!
              y1 -= cue_font_size
              draw_cue_name(p , name_x , y1 , jumpin , name_width , cue_font_size)
              unless (dont_finish_here[jumpin.finish] == true) then
                p.line(bracket_x - bracket_stroke_width / 2 , y2 , bracket_x2 , y2).stroke
                p.add_text_wrap(bracket_x2 + 6 , y2 -4 , name_width, "<i>" + jumpin.finish_time + "</i>" , @finish_time_font_size,:left)         
                draw_arrow(p,bracket_x2 + 5 , y2) 
              end          
            end

            jumpout = strip.regions.find do |r|
              (r.finish > row_finish) and (r.start >= row_start) and (r.start <= row_finish) 
            end          

            if jumpout then
              #$stderr.print "Drawing \"#{jumpout.name}\" as a jumpout.\n"
              this_start_row = row_page.find {|a_pg| a_pg[0] == jumpout.start}
              y1 , y2 = this_start_row[2] - @time_font_size , grid_bottom 
            
              if jumpout.shade? then
                p.save_state
                shade_y =  am_finishing_here[jumpout.start] ? y1 + @time_font_size : y1 - bracket_start_y_offset
                poly_points = [ [ bracket_x , shade_y ], 
                                [ bracket_x , y2 ] , 
                                [ strip_x + strip_width , y2] , 
                                [ strip_x + strip_width , shade_y ]]
                p.stroke_style! PDF::Writer::StrokeStyle.new( 0 )
                p.fill_color(Color::RGB.from_fraction( 0.95, 0.95, 0.95 ))
                p.polygon(poly_points).fill
                p.restore_state
              end
            
              p.line(bracket_x , y1 - bracket_start_y_offset , bracket_x , y2).stroke           
              p.add_text_wrap(time_x, y1,time_width,"<b>" + jumpout.start_time + "</b>",@time_font_size,:left)
              y1 -= cue_font_size
              draw_cue_name(p , name_x , y1 , jumpout , name_width , cue_font_size)
            end        
            withins = strip.regions.find_all do |r|
              r.start >= row_start and r.finish <= row_finish
            end
          
            withins.each do |within|
              #$stderr.print "Drawing \"#{within.name}\" as a within.\n"       
              this_start_row = row_page.find {|a_pg| a_pg[0] == within.start}
              this_finish_row = row_page.find {|a_pg| a_pg[0] == within.finish}
              raise RuntimeError if (this_start_row == nil or this_finish_row == nil)
              y1 = this_start_row[2] - @time_font_size        
              y2 = this_finish_row[2]
              y2 -= @finish_time_font_size/2 unless (dont_finish_here[within.finish] == true)
              unless (within.start == within.finish) then         
              
                if within.shade? then
                  p.save_state
                  shade_y =  am_finishing_here[within.start] ? y1 + @time_font_size : y1 - bracket_start_y_offset
                  poly_points = [ [ bracket_x , shade_y ], 
                                  [ bracket_x , y2 ] , 
                                  [ strip_x + strip_width , y2] , 
                                  [ strip_x + strip_width , shade_y ]]
                  p.stroke_style! PDF::Writer::StrokeStyle.new( 0 )
                  p.fill_color(Color::RGB.from_fraction( 0.95, 0.95, 0.95 ))
                  p.polygon(poly_points).fill
                  p.restore_state
                end
              
                  p.line(bracket_x , y1 - bracket_start_y_offset , bracket_x , y2).stroke
              end
              p.add_text_wrap(time_x, y1,time_width,"<b>" + within.start_time + "</b>",@time_font_size,:left)
              y1 -= @time_font_size
              draw_cue_name(p , name_x , y1 , within , name_width , cue_font_size)
              unless ((dont_finish_here[within.finish] == true) or within.start == within.finish ) then
                p.line(bracket_x - bracket_stroke_width / 2 , y2 , bracket_x2 , y2).stroke
                p.add_text_wrap(bracket_x2 + 6 , y2 - 4 , name_width, "<i>" + within.finish_time + "</i>" , @finish_time_font_size,:left)
                draw_arrow(p,bracket_x2 + 5 , y2)           
              end
            end
          
          end
        end #each strip
        p.new_page unless pg == strip_pages.last && row_page == row_pages.last
      end #each strip_page
    end #each row_page
    p
  end #def

  def cue_height(p,session,region,strip_width)
    cue_lines = region.name_lines.size
    region.name_lines.each do |line|
      str = line
      cue_lines -= 1 unless str == ''
      while (str != '') do
        str = p.add_text_wrap(100, 100, strip_width - 8,str,session.cue_font_size,:left , 0 , true)
        cue_lines += 1
      end
    end
  
    @time_font_size + \
    session.cue_font_size * cue_lines + 8
  end

  def draw_cue_name(p,x,y,region,width,font_size)
    #$stderr.print "- Drawing cue name \"#{region.name}\"\n"
    text_ary , y_acc = region.name_lines , y
    text_ary.each do |line|
      text_acc , more_text = line , true
      while (more_text) do
        #$stderr.print "-- Drawing cue name line \"#{text_acc}\"\n"
        text_acc = p.add_text_wrap(x, y_acc,width ,text_acc,font_size,:left)
        y_acc -= font_size
        more_text = false if text_acc == ''
      end
    end
  end

  def draw_arrow(p,x,y)
    p.save_state
    p.stroke_color! Color::RGB::Black
    p.stroke_style! PDF::Writer::StrokeStyle.new(0.1)
    p.move_to(x,y)
    p.fill_color! Color::RGB::Black
    p.line_to(x - 8 , y + 6).line_to(x-8,y-6).fill_stroke
    p.restore_state
  end
end #class