class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
    	t.string "name"
    	t.string "abbr"
    	t.string "stadium"
    	t.string "zipcode"
    	t.integer "timezone"
      t.timestamps
    end

    add_index("teams", "name")
    add_index("teams", "abbr")
    
  end
end
