class CreateSeasonsAndTeams < ActiveRecord::Migration
  def change
    create_table :seasons_teams do |t|
      t.belongs_to :season, index: true
      t.belongs_to :team, index: true
    end
  end
end
