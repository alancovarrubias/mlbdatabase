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


  def opp_righties
    self.batters_handedness("R")
  end

  def opp_lefties
    self.batters_handedness("L")
  end
  

  def num_lefties(pitcher, batters)

    unless pitcher
      return 0, 0
    end
    
    pitcher = pitcher.player
    batters = batters.map { |batter| batter.player }

    same = diff = 0
    batters.each do |batter|
      if pitcher.throwhand == batter.bathand
        same += 1
      else
        diff += 1
      end
    end

    if pitcher.throwhand == "R"
      return diff, same
    else
      return same, diff
    end

  end














  def sort_by_bullpen
    unless self.game
      return nil
    end
    game_day = self.game.game_day.prev_day(1)
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
