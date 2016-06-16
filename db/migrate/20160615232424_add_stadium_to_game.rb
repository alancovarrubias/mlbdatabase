class AddStadiumToGame < ActiveRecord::Migration
  def change
    add_column :games, :stadium, :string, default: ""
    add_column :games, :away_runs, :integer
    add_column :games, :home_runs, :integer
  end
end
