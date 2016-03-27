class CreateInnings < ActiveRecord::Migration
  def change
    create_table :innings do |t|
    	t.belongs_to :game
    	t.string "number", :default => ""
    	t.string "away", :default => ""
    	t.string "home", :default => ""
      t.timestamps
    end
  end
end
