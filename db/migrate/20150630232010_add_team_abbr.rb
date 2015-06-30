class AddTeamAbbr < ActiveRecord::Migration
  def change
  	add_column("teams", :team_abbr, :string)
  	add_index("teams", :team_abbr)
  end
end
