class AddTeamIndex < ActiveRecord::Migration
  def change
  	add_column("teams", :fangraph_id, :integer)
  	add_index("teams", :fangraph_id)
  end
end
