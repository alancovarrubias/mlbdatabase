class CreatePitcherBoxScores < ActiveRecord::Migration
  def change
    create_table :pitcher_box_scores do |t|

    	t.belongs_to :game, :default => nil
    	t.belongs_to :pitcher, :default => nil
    	t.boolean "home", :default => false
    	t.string "name", :default => ''
    	t.float "IP", :default => 0
    	t.integer "TBF", :default => 0
    	t.integer "H", :default => 0
    	t.integer "HR", :default => 0
    	t.integer "ER", :default => 0
    	t.integer "BB", :default => 0
    	t.integer "SO", :default => 0
    	t.float "FIP", :default => 0
    	t.float "pLI", :default => 0
    	t.float "WPA", :default => 0

      t.timestamps
    end
  end
end
