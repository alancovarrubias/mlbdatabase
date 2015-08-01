class ChangeColumnDefault < ActiveRecord::Migration
  def change
  	change_column_default("games", :away_money_line, "")
  	change_column_default("games", :home_money_line, "")
  	change_column_default("games", :away_total, "")
  	change_column_default("games", :home_total, "")
  end
end
