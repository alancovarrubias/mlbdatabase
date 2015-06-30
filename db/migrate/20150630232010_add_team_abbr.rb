class AddTeamAbbr < ActiveRecord::Migration
  def change
  	add_column("teams", :game_abbr, :string)
  	add_index("teams", :game_abbr)
  end
end
