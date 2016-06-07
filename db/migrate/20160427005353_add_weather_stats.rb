class AddWeatherStats < ActiveRecord::Migration
  def change
  	add_column :weathers, :speed, :string, default: ""
  	add_column :weathers, :dir,   :string, default: ""
  end
end
