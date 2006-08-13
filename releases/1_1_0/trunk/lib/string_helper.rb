#  Created by Jamie Hardt on 2006-06-27.
#  Copyright (c) 2006. All rights reserved.

class String
  
  def /(str)
    self + File::SEPARATOR + str
  end
  
end