class ChangeFbToIp < ActiveRecord::Migration
  def change
  	add_column(:pitchers, :IP_previous_L, :float, :default => 0)
  	add_column(:pitchers, :IP_previous_R, :float, :default => 0)
  end
end
