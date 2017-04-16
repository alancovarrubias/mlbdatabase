class AddOrderToGames < ActiveRecord::Migration
  def change
    add_column :games, :time_order, :integer, default: 0
  end
end
