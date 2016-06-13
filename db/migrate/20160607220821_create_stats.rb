class CreateStats < ActiveRecord::Migration
  def change
    create_table :stats do |t|
      t.float :spot
      t.float :usd_avail
      t.float :usd_bal
      t.float :btc_avail
      t.float :btc_bal
      t.float :move

      t.timestamps null: false
    end
  end
end
