# track.rb
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

require 'pt/region'

module PT
  class Track

    attr_reader :session
    attr_reader :regions
    attr_accessor :name
    attr_accessor :channel

    def initialize(s)
      @session = s
      @regions = []
      @name = "(blank)"
      @channel = 0
    end
    
    def create_region(&block)
      r= Region.new(self)
      block.call(r)
      @regions << r
      @regions.sort!
      r
    end


    def add_region(name = '(blank)' , start = '', finish = '')
      create_region do |r|
        r.name, r.start_time, r.finish_time = name , start , finish
      end
    end
    
    def add_primitive_region(name,start,finish)
      create_region do |r|
        r.name, r.start, r.finish = name , start , finish
      end
    end

    def reframe!
      @regions.each {|r| r.reframe! }
    end

    def update(region)
      impose! region
      @regions.sort!
    end

    def impose!(imposing_region)      
      overwritten = @regions.delete_if do |region|
        region.start >= imposing_region.start && \
        region.finish <= imposing_region.finish && \
        region.object_id != imposing_region.object_id 
      end
      
      trim_tail = @regions.find do |region|
        region.finish > imposing_region.start && \
        region.start < imposing_region.start && \
        region.finish < imposing_region.finish
      end
      trim_tail.finish = imposing_region.start if trim_tail
      
      trim_head = @regions.find do |region|
        region.start < imposing_region.finish && \
        region.finish > imposing_region.finish && \
        region.start > imposing_region.start
      end
      trim_head.start = imposing_region.finish if trim_head
    end

    def delete_all_regions!
      @regions = []
    end
  end
end