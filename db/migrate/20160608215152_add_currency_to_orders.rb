class AddCurrencyToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :currency, :string
  end
end
