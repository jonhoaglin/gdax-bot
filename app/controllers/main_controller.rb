class MainController < ApplicationController
  def index
    @stat = Stat.last
    @orders = Order.all
  end
end
