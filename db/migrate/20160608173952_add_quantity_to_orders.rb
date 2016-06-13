class AddQuantityToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :quantity, :float
  end
end
