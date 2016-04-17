class CreateWeathers < ActiveRecord::Migration
  def change
    create_table :weathers do |t|
      t.belongs_to :game, index: true
      t.string :station,  default: ""
      t.integer :hour,    default: 0
      t.string :wind,     default: ""
      t.string :humidity, default: ""
      t.string :pressure, default: ""
      t.string :temp,     default: ""
      t.string :rain,     default: ""
      t.timestamps
    end
    add_belongs_to :games, :game_day, index: true
  end
end
