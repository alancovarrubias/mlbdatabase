class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.belongs_to :team, 		index: true
	    t.string :name,			    default: ""
	    t.string :identity,		  default: ""
      t.integer :fangraph_id
      t.boolean :starter,     default: false
      t.boolean :bullpen,     default: false
      t.string :bathand, 		  default: ""
      t.string :throwhand, 		default: ""
      t.timestamps
    end
  end
end
