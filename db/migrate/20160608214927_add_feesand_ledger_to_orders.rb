class AddFeesandLedgerToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :fees, :float
    add_column :orders, :ledger, :float
  end
end
