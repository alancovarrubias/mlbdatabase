class AddRowToModels < ActiveRecord::Migration
  def change
  	add_column(:hitters, :FB_L, :float, default: 0.0)
  	add_column(:hitters, :FB_R, :float, default: 0.0)
  	add_column(:hitters, :FB_14, :float, default: 0.0)
  	add_column(:hitters, :FB_previous_L, :float, default: 0.0)
  	add_column(:hitters, :FB_previous_R, :float, default: 0.0)
  	add_column(:hitters, :GB_L, :float, default: 0.0)
  	add_column(:hitters, :GB_R, :float, default: 0.0)
  	add_column(:hitters, :GB_14, :float, default: 0.0)
  	add_column(:hitters, :GB_previous_L, :float, default: 0.0)
  	add_column(:hitters, :GB_previous_R, :float, default: 0.0)
  	add_column(:hitters, :OPS_L, :integer, default: 0.0)
  	add_column(:hitters, :OPS_R, :integer, default: 0.0)
  	add_column(:hitters, :OPS_14, :integer, default: 0.0)
  	add_column(:hitters, :OPS_previous_L, :integer, default: 0.0)
  	add_column(:hitters, :OPS_previous_R, :integer, default: 0.0)
  end
end
