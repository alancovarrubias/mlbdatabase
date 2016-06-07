class Add2016Attributes < ActiveRecord::Migration
  def change
  	add_column :pitchers, :FIP_next, :integer, default: 0
  	add_column :pitchers, :LD_next_L, :float, default: 0.0
  	add_column :pitchers, :WHIP_next_L, :float, default: 0.0
  	add_column :pitchers, :IP_next_L, :float, default: 0.0
  	add_column :pitchers, :SO_next_L, :integer, default: 0
  	add_column :pitchers, :BB_next_L, :integer, default: 0
  	add_column :pitchers, :ERA_next_L, :float, default: 0.0
  	add_column :pitchers, :wOBA_next_L, :integer, default: 0
  	add_column :pitchers, :FB_next_L, :float, default: 0.0
  	add_column :pitchers, :GB_next_L, :float, default: 0.0
  	add_column :pitchers, :xFIP_next_L, :float, default: 0
  	add_column :pitchers, :KBB_next_L, :float, default: 0.0
  	add_column :pitchers, :OPS_next_L, :integer, default: 0.0
  	add_column :pitchers, :LD_next_R, :float, default: 0.0
  	add_column :pitchers, :WHIP_next_R, :float, default: 0.0
  	add_column :pitchers, :IP_next_R, :float, default: 0.0
  	add_column :pitchers, :SO_next_R, :integer, default: 0
  	add_column :pitchers, :BB_next_R, :integer, default: 0
  	add_column :pitchers, :ERA_next_R, :float, default: 0.0
  	add_column :pitchers, :wOBA_next_R, :integer, default: 0
  	add_column :pitchers, :FB_next_R, :float, default: 0.0
  	add_column :pitchers, :GB_next_R, :float, default: 0.0
  	add_column :pitchers, :xFIP_next_R, :float, default: 0
  	add_column :pitchers, :KBB_next_R, :float, default: 0.0
  	add_column :pitchers, :OPS_next_R, :integer, default: 0.0

  	add_column :hitters, :SB_next_L, :integer, default: 0
  	add_column :hitters, :wOBA_next_L, :integer, default: 0
  	add_column :hitters, :OBP_next_L, :integer, default: 0
  	add_column :hitters, :SLG_next_L, :integer, default: 0
  	add_column :hitters, :AB_next_L, :integer, default: 0
  	add_column :hitters, :BB_next_L, :integer, default: 0
  	add_column :hitters, :SO_next_L, :integer, default: 0
  	add_column :hitters, :LD_next_L, :float, default: 0.0
  	add_column :hitters, :wRC_next_L, :integer, default: 0
  	add_column :hitters, :FB_next_L, :integer, default: 0
  	add_column :hitters, :GB_next_L, :integer, default: 0
  	add_column :hitters, :OPS_next_L, :integer, default: 0
  	add_column :hitters, :SB_next_R, :integer, default: 0
  	add_column :hitters, :wOBA_next_R, :integer, default: 0
  	add_column :hitters, :OBP_next_R, :integer, default: 0
  	add_column :hitters, :SLG_next_R, :integer, default: 0
  	add_column :hitters, :AB_next_R, :integer, default: 0
  	add_column :hitters, :BB_next_R, :integer, default: 0
  	add_column :hitters, :SO_next_R, :integer, default: 0
  	add_column :hitters, :LD_next_R, :float, default: 0.0
  	add_column :hitters, :wRC_next_R, :integer, default: 0
  	add_column :hitters, :FB_next_R, :integer, default: 0
  	add_column :hitters, :GB_next_R, :integer, default: 0
  	add_column :hitters, :OPS_next_R, :integer, default: 0

  end
end
