class AddSieraToPitchers < ActiveRecord::Migration
  def change
    add_column :pitcher_stats, :siera, :float, default: 0.0
  end
end
