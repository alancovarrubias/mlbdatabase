class AddWeatherAttributes < ActiveRecord::Migration
  def change
  	add_column :weathers, :dew, :string, default: ""
  	add_column :weathers, :feel, :string, default: ""
  end
end
