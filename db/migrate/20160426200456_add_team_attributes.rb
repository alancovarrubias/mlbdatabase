class AddTeamAttributes < ActiveRecord::Migration
  def change
  	add_column :teams, :city, :string, default: ""
  end
end
