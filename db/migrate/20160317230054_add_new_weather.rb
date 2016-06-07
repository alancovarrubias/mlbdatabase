class AddNewWeather < ActiveRecord::Migration
  def change
  	add_column("games", :wind_1_value, :string, :default => "")
  	add_column("games", :humidity_1_value, :string, :default => "")
  	add_column("games", :pressure_1_value, :string, :default => "")
  	add_column("games", :temperature_1_value, :string, :default => "")
  	add_column("games", :precipitation_1_value, :string, :default => "")
  	add_column("games", :wind_2_value, :string, :default => "")
  	add_column("games", :humidity_2_value, :string, :default => "")
  	add_column("games", :pressure_2_value, :string, :default => "")
  	add_column("games", :temperature_2_value, :string, :default => "")
  	add_column("games", :precipitation_2_value, :string, :default => "")
  	add_column("games", :wind_3_value, :string, :default => "")
  	add_column("games", :humidity_3_value, :string, :default => "")
  	add_column("games", :pressure_3_value, :string, :default => "")
  	add_column("games", :temperature_3_value, :string, :default => "")
  	add_column("games", :precipitation_3_value, :string, :default => "")
  end
end
