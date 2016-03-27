class CreateHitters < ActiveRecord::Migration
  def change
    create_table :hitters do |t|
    	t.belongs_to :team, :default => nil
      t.belongs_to :game, :default => nil
    	t.string "name", :default => ""
    	t.string "alias", :default => ""
      t.integer "fangraph_id", :default => 0
      t.string "bathand", :default => ""
      t.string "throwhand", :default => ""
      t.integer "lineup", :default => 0
      t.boolean "starter", :default => false
      t.integer "SB_L", :default => 0
      t.integer "wOBA_L", :default => 0
      t.integer "OBP_L", :default => 0
      t.integer "SLG_L", :default => 0
      t.integer "AB_L", :default => 0
      t.integer "BB_L", :default => 0
      t.integer "SO_L", :default => 0
      t.float "LD_L", :default => 0
      t.integer "wRC_L", :default => 0
      t.integer "SB_R", :default => 0
      t.integer "wOBA_R", :default => 0
      t.integer "OBP_R", :default => 0
      t.integer "SLG_R", :default => 0
      t.integer "AB_R", :default => 0
      t.integer "BB_R", :default => 0
      t.integer "SO_R", :default => 0
      t.float "LD_R", :default => 0
      t.integer "wRC_R", :default => 0
      t.integer "wOBA_14", :default => 0
      t.integer "OBP_14", :default => 0
      t.integer "SLG_14", :default => 0
      t.integer "AB_14", :default => 0
      t.integer "BB_14", :default => 0
      t.integer "SB_14", :default => 0
      t.integer "SO_14", :default => 0
      t.float "LD_14", :default => 0
      t.integer "wRC_14", :default => 0
      t.integer "SB_previous_L", :default => 0
      t.integer "wOBA_previous_L", :default => 0
      t.integer "OBP_previous_L", :default => 0
      t.integer "SLG_previous_L", :default => 0
      t.integer "AB_previous_L", :default => 0
      t.integer "BB_previous_L", :default => 0
      t.integer "SO_previous_L", :default => 0
      t.float "LD_previous_L", :default => 0
      t.integer "wRC_previous_L", :default => 0
      t.integer "SB_previous_R", :default => 0
      t.integer "wOBA_previous_R", :default => 0
      t.integer "OBP_previous_R", :default => 0
      t.integer "SLG_previous_R", :default => 0
      t.integer "AB_previous_R", :default => 0
      t.integer "BB_previous_R", :default => 0
      t.integer "SO_previous_R", :default => 0
      t.float "LD_previous_R", :default => 0
      t.integer "wRC_previous_R", :default => 0
      t.timestamps
    end

    add_index("hitters", "name")
    add_index("hitters", "alias")
    add_index("hitters", "fangraph_id")

  end
end
