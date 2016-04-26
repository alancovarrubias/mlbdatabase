class AddStatsToPitchers < ActiveRecord::Migration
  def change
  	add_column :lancers, :ip, :float, default: 0.0
  	add_column :lancers, :bb, :integer, default: 0
  	add_column :lancers, :h,  :integer, default: 0
  	add_column :lancers, :r,  :integer, default: 0
  	add_column :lancers, :np, :integer, default: 0
  	add_column :lancers, :s,  :integer, default: 0
  end
end
