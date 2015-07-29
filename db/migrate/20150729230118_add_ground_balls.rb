class AddGroundBalls < ActiveRecord::Migration
  def change
  	add_column("pitchers", :GB_R, :float, :default => 0.0)
  	add_column("pitchers", :GB_L, :float, :default => 0.0)
  	add_column("pitchers", :GB_previous_R, :float, :default => 0.0)
  	add_column("pitchers", :GB_previous_L, :float, :default => 0.0)
  end
end
