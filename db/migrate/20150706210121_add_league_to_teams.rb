class AddLeagueToTeams < ActiveRecord::Migration
  def change
  	add_column("teams", "league", :string, :default => "")
  	add_column("teams", "division", :string, :default => "")
  end
end
