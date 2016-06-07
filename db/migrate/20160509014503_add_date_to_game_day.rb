class AddDateToGameDay < ActiveRecord::Migration
  def change
    add_column :game_days, :date, :date
  end
end
