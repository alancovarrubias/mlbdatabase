class AddTomorrowStarters < ActiveRecord::Migration
  def change
  	add_column("pitchers", :tomorrow_starter, :string)
  end
end
