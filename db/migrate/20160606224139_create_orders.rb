class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.string :buy_id
      t.float :buy
      t.string :sell_id
      t.float :sell

      t.timestamps null: false
    end
  end
end
