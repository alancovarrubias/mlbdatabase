class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
    	t.string "name", :default => ""
    	t.string "abbr", :default => ""
    	t.string "stadium", :default => ""
    	t.string "zipcode", :default => ""
    	t.integer "timezone", :default => 0
      t.timestamps
    end

    add_index("teams", "name")
    add_index("teams", "abbr")
    
  end
end
