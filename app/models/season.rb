class Season < ActiveRecord::Base
  has_many :game_days
  has_many :lancers
  has_many :batters

  def self.create_seasons
    Season.create(year: 2016)
  end

  def create_players
    player_creator = Create::Players.new
    Team.all.each do |team|
      player_creator.create(self, team)
      player_creator.fangraphs(team)
    end
  end

  def update_batters
    batter_updater = Update::Batters.new
    Team.all.each do |team|
      batter_updater.update(self, team)
    end
  end

  def update_pitchers
    pitcher_updater = Update::Pitchers.new
    Team.all.each do |team|
      pitcher_updater.update(self, team)
    end
  end

  def create_games
    game_creator = Create::Games.new
    Team.all.each do |team|
      game_creator.create(self, team)
    end
  end

end
