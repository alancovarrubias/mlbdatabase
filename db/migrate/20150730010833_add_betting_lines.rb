class AddBettingLines < ActiveRecord::Migration
  def change
  	add_column("games", :away_money_line, :string, :default => "")
  	add_column("games", :home_money_line, :string, :default => "")
  	add_column("games", :away_total, :string, :default => "")
  	add_column("games", :home_total, :string, :default => "")
  end
end
