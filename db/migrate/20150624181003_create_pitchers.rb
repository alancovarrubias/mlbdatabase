class CreatePitchers < ActiveRecord::Migration
  def change
    create_table :pitchers do |t|
    	t.belongs_to :team
      t.belongs_to :game
    	t.string "name"
    	t.string "alias"
      t.string "bathand"
      t.string "throwhand"
      t.boolean "starter", :default => false
      # previous bullpen pitches
      t.boolean "bullpen", :default => false
      t.integer "one"
      t.integer "two"
      t.integer "three"
      # statistics
      t.integer "FIP", :default => 0 # actuall FIP-
      t.float "LD_L", :default => 0
      t.float "WHIP_L", :default => 0
      t.float "IP_L", :default => 0
      t.integer "SO_L", :default => 0
      t.integer "BB_L", :default => 0
      t.float "ERA_L", :default => 0
      t.integer "wOBA_L", :default => 0
      t.float "FB_L", :default => 0
      t.float "xFIP_L", :default => 0
      t.float "KBB_L", :default => 0
      t.float "LD_R", :default => 0
      t.float "WHIP_R", :default => 0
      t.float "IP_R", :default => 0
      t.integer "SO_R", :default => 0
      t.integer "BB_R", :default => 0
      t.float "ERA_R", :default => 0
      t.integer "wOBA_R", :default => 0
      t.float "FB_R", :default => 0
      t.float "xFIP_R", :default => 0
      t.float "KBB_R", :default => 0
      t.float "LD_30", :default => 0
      t.float "WHIP_30", :default => 0
      t.float "IP_30", :default => 0
      t.integer "SO_30", :default => 0
      t.integer "BB_30", :default => 0
      t.integer "FIP_previous", :default => 0
      t.float "FB_previous_L", :default => 0
      t.float "FB_previous_R", :default => 0
      t.float "xFIP_previous_L", :default => 0
      t.float "xFIP_previous_R", :default => 0
      t.float "KBB_previous_L", :default => 0
      t.float "KBB_previous_R", :default => 0
      t.integer "wOBA_previous_L", :default => 0
      t.integer "wOBA_previous_R", :default => 0
      t.timestamps
    end

    add_index("pitchers", "name")
    add_index("pitchers", "alias")
    
  end
end
