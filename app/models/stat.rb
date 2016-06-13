class Stat < ActiveRecord::Base
  def total
    (self.usd_bal+(0.9975*self.spot*self.btc_bal))
  end
  
  def fee
    (0.0025*self.spot)
  end
end
