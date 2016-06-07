class CreateBatters < ActiveRecord::Migration
  def change
    create_table :batters do |t|
      t.belongs_to :team,        index: true
      t.belongs_to :game,   	   index: true
      t.belongs_to :player, 	   index: true
      t.belongs_to :season, 	   index: true
      t.boolean    :starter, 	   default: false
      t.integer    :lineup,        default: 0
      t.string     :position,      default: ""
      t.timestamps
    end
  end
end
