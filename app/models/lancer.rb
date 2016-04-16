class Lancer < ActiveRecord::Base
  belongs_to :team
  belongs_to :player
  belongs_to :game
  belongs_to :season
  has_many   :pitcher_stats, dependent: :destroy

  def self.starters
    Lancer.where(game_id: nil, starter: true)
  end

  def self.bullpen
    Lancer.where(game_id: nil, bullpen: true)
  end

  def stats(handedness=nil)
  	if self.pitcher_stats.size == 0
  	  PitcherStat.create(lancer_id: self.id, range: "Season", handedness: "L")
      PitcherStat.create(lancer_id: self.id, range: "Season", handedness: "R")
      PitcherStat.create(lancer_id: self.id, range: "30 Days", handedness: "")
  	end
    unless handedness
      return self.pitcher_stats
    else
      return self.pitcher_stats.where(handedness: handedness).first
    end
  end

  def create_game_stats
  	lancer = self.player.create_lancer(self.season)
  	lancer.stats.order("id").each do |stat|
  	  new_stat = stat.dup
  	  new_stat.lancer_id = self.id
  	  new_stat.save
  	end
  end

end
