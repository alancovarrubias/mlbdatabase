class CreateHitterBoxScores < ActiveRecord::Migration
  def change
    create_table :hitter_box_scores do |t|

    	t.belongs_to :game, :default => nil
    	t.belongs_to :hitter, :default => nil
    	t.boolean "home", :default => false
    	t.string "name", :default => ''
      	t.integer "BO", :default => 0
    	t.integer "PA", :default => 0
    	t.integer "H", :default => 0
    	t.integer "HR", :default => 0
    	t.integer "R", :default => 0
    	t.integer "RBI", :default => 0
    	t.integer "BB", :default => 0
    	t.integer "SO", :default => 0
    	t.integer "wOBA", :default => 0
    	t.float "pLI", :default => 0
    	t.float "WPA", :default => 0

      t.timestamps
    end
  end
end
