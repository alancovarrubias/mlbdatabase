class AddHitsToPitcherStat < ActiveRecord::Migration
  def change
  	add_column :pitcher_stats, :h, :integer, default: 0
  end
end
