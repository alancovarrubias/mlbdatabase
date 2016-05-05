class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.references :game_day, index: true, foreign_key: true
      t.references :player,   index: true, foreign_key: true
      t.references :team,     index: true, foreign_key: true
      t.text	   :desc,   default: ""
      t.timestamps
    end
  end
end
