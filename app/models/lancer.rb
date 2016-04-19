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
      return self.pitcher_stats.find_by(handedness: handedness)
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

  def throwhand
    self.player.throwhand
  end







  def batters_handedness(hand)

    unless game = self.game
      return nil
    end

    opp_team = self.team == game.away_team ? game.home_team : game.away_team
    opp_batters = game.batters.where(team_id: opp_team.id)

    count = 0
    opp_batters.where(team_id: opp_team.id).each do |batter|

      if batter.throwhand == hand
        count += 1
      end

    end

    return count

  end
  


  def sort_bullpen

    num_size = [10, 8, 6, 4, 2]
    count = 0
    (1..5).each_with_index do |days, index|
      game_day = self.game.game_day.prev_day(days)
      unless game_day
        next
      end
      game_ids = game_day.games.map { |game| game.id }
      lancer = Lancer.find_by(player_id: self.player_id, game_id: game_ids)

      if lancer
        count += lancer.pitches * 10 ** num_size[index]
      end
    end

    return count

  end


  def prev_bullpen_pitches(days)

    unless self.game
      return nil
    end
    game_day = self.game.game_day.prev_day(days)
    unless game_day
      return 0
    end
    games = game_day.games
    game_ids = games.map { |game| game.id }
    lancer = Lancer.find_by(player_id: self.player_id, game_id: game_ids)
    if lancer
      return lancer.pitches
    else
      return 0
    end
  end

end
