class Order < ActiveRecord::Base
  def diff
    if self.sell.blank?
      0
    else
      (self.quantity*self.sell) - (self.quantity*self.buy)
    end
  end
  
  def profit
    if self.sell.blank?
      0
    else
      self.diff - self.fees
    end
  end
end
