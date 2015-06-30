class AddTeamAbbr < ActiveRecord::Migration
  def change
  	add_column("teams", :team_abbr, :integer)
  	add_index("teams", :team_abbr)
  end
end
