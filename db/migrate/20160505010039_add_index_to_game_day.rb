class AddIndexToGameDay < ActiveRecord::Migration
  def change
  	add_column :game_days, :index, :integer, default: 0
  end
end
