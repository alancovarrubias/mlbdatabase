class Batter < ActiveRecord::Base
  belongs_to :team
  belongs_to :player
  belongs_to :game
  belongs_to :season
  # belongs_to :owner, polymorphic: true
  has_many   :batter_stats, dependent: :destroy

  def self.starters
    where(game_id: nil, starter: true)
  end

  def stats(handedness=nil)
  	if self.batter_stats.size == 0
  	  BatterStat.create(batter_id: self.id, range: "Season", handedness: "L")
      BatterStat.create(batter_id: self.id, range: "Season", handedness: "R")
      BatterStat.create(batter_id: self.id, range: "14 Days", handedness: "")
  	end
    unless handedness
  	  return batter_stats
    else
      return batter_stats.find_by(handedness: handedness)
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

  def bathand
    player.bathand
  end



end
