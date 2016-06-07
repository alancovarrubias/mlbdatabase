class CreateLancers < ActiveRecord::Migration
  def change
    create_table :lancers do |t|
      t.belongs_to :team,        index: true
      t.belongs_to :game,   	   index: true
      t.belongs_to :player, 	   index: true
      t.belongs_to :season, 	   index: true
      t.boolean    :starter, 	   default: false
      t.boolean    :bullpen,	   default: false
      t.integer	   :pitches, 	   default: 0

      t.timestamps
    end
  end
end
