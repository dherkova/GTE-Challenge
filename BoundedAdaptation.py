# This is a class to run an adaptive iterative process, assuming an underlying
# monotonically rising function f(x).

# Far later: Another, probably clear way to go about this is to find upper and
# lower bounds first, and then use extrapolation from these bounds to get at the
# optimal value (as opposed to the last two values used). The advantage would be
# that f(x) does not have to be monotonically rising any more, with the
# disadvantage that there would be no obvious way of getting the second bound.


class BoundedAdaptationRunner:
  
  def __init__(self, left_x, right_x, lower_y, upper_y, initial_x, target_y):
    self.bounds_left_x = left_x
    self.bounds_right_x = right_x
    self.bounds_lower_y = lower_y
    self.bounds_upper_y = upper_y
    self.last_y_values = []
    self.last_x_values = [initial_x]
    self.target_value_of_y = target_y
  
  def __iteration_count(self):
    return len(self.last_y_values)
  
  def __last_absolute_change_in_y(self):
    if self.__iteration_count() < 2:
      return None
    return abs(self.last_y_values[-1] - self.last_y_values[-2])
  
  def next(self, last_value_of_y):
    if self.__iteration_count() > 0:
      # Update bounds
      if last_value_of_y > self.target_value_of_y:
        if last_value_of_y < self.bounds_upper_y or (last_value_of_y==self.bounds_upper_y and self.last_x_values[-1]<self.bounds_upper_x):
          print "DEBUG: New upper bound found."
          self.bounds_upper_y = last_value_of_y
          self.bounds_right_x = self.last_x_values[-1]
      else:
        if last_value_of_y > self.bounds_lower_y or (last_value_of_y==self.bounds_lower_y and self.last_x_values[-1]>self.bounds_lower_x):
          print "DEBUG: New lower bound found."
          self.bounds_lower_y = last_value_of_y
          self.bounds_left_x = self.last_x_values[-1]
    
    print "DEBUG: current bounds: ("+str(self.bounds_left_x)+", "+str(self.bounds_lower_y)+") and ("+str(self.bounds_right_x)+", "+str(self.bounds_upper_y)+")"
    next_value_of_x = None
    # Save last outcome
    self.last_y_values.append(last_value_of_y)
    
    if self.__iteration_count() < 2:
      print "\n--- DEBUG: Adaptation stage I.: Initial run ---"
      next_value_of_x = self.last_x_values[0]
      
    elif self.__iteration_count() == 2 or self.__last_absolute_change_in_y() == 0.0:
      # Initially, just change x value by 10% to see what happens
      print "\n--- DEBUG: Adaptation stage II.: Changing weight by 10% ---"
      if last_value_of_y > self.target_value_of_y:
        next_value_of_x = self.last_x_values[0] * 0.9
      else:
        next_value_of_x = self.last_x_values[0] * 1.1
      
    else:
      # Since we now have enough data, we can extrapolate
      print "\n--- DEBUG: Adaptation stage III.: Linear extrapolation ---"
      next_value_of_x = ((self.target_value_of_y-self.last_y_values[-2])*(self.last_x_values[-1]-self.last_x_values[-2]) / (self.last_y_values[-1]-self.last_y_values[-2])) + self.last_x_values[-2]
      # Check if we are out of the bounds (to avoid oscillations)
      if next_value_of_x > self.bounds_right_x or next_value_of_x < self.bounds_left_x:
        print "DEBUG: Extrapolated value of {w} is out of best bounds, resetting...".format(w=next_value_of_x)
        next_value_of_x = 0.5*(self.bounds_left_x + self.bounds_right_x)
    
    if self.__iteration_count() > 0:
      self.last_x_values.append(next_value_of_x)
    # print "DEBUG: resulting next x-value: "+str(next_value_of_x)
    return next_value_of_x
  

