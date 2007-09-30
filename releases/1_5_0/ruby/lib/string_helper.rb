#  Created by Jamie Hardt on 2006-06-27.
#  Copyright (c) 2006. All rights reserved.

class String
  
  # Conatenates a File::SEPARATOR to the end of the receiver and then adds the string argument.
  def /(str)
    self + File::SEPARATOR + str
  end
  
end