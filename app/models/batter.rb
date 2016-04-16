class Batter < ActiveRecord::Base
  belongs_to :team
  belongs_to :player
  belongs_to :game
  belongs_to :season
  has_many   :batter_stats, dependent: :destroy

  def self.starters
    Lancer.where(game_id: nil, starter: true)
  end

  def stats(handedness=nil)
  	if self.batter_stats.size == 0
  	  BatterStat.create(batter_id: self.id, range: "Season", handedness: "L")
      BatterStat.create(batter_id: self.id, range: "Season", handedness: "R")
      BatterStat.create(batter_id: self.id, range: "14 Days", handedness: "")
  	end
    unless handedness
  	  return self.batter_stats
    else
      return self.batter_stats.where(handedness: handedness).first
    end
  end

  def create_game_stats
    batter = self.player.create_batter(self.season)
    batter.stats.order("id").each do |stat|
      new_stat = stat.dup
      new_stat.batter_id = self.id
      new_stat.save
    end
  end



end
