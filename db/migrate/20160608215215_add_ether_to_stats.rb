class AddEtherToStats < ActiveRecord::Migration
  def change
    add_column :stats, :eth_avail, :float
    add_column :stats, :eth_bal, :float
  end
end
