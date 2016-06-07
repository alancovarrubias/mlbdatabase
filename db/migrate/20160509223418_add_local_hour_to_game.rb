class AddLocalHourToGame < ActiveRecord::Migration
  def change
    add_column :games, :local_hour, :integer, default: 0
  end
end
