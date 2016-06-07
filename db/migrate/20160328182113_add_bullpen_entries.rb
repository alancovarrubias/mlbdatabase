class AddBullpenEntries < ActiveRecord::Migration
  def change
  	add_column(:pitchers, :four, :integer, :default => 0)
  	add_column(:pitchers, :five, :integer, :default => 0)
  end
end
