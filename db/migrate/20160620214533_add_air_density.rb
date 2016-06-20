class AddAirDensity < ActiveRecord::Migration
  def change
    add_column :weathers, :air_density, :float, default: 0.0
  end
end
