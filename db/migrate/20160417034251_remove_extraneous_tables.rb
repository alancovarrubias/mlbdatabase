class RemoveExtraneousTables < ActiveRecord::Migration
  def change
  	drop_table :hitters
  	drop_table :pitchers
  end
end
