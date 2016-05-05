class Lancer < ActiveRecord::Base
  belongs_to :team
  belongs_to :player
  belongs_to :game
  belongs_to :season
  has_many   :pitcher_stats, dependent: :destroy

  include PlayerUpdate

  def self.starters
    where(game_id: nil, starter: true)
  end

  def self.bullpen
    where(game_id: nil, bullpen: true)
  end

  def name
    player.name
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
  	lancer = player.create_lancer(self.season)
  	lancer.stats.order("id").each do |stat|
  	  new_stat = stat.dup
  	  new_stat.lancer_id = self.id
  	  new_stat.save
  	end
  end

  def throwhand
    player.throwhand
  end

  def opp_team
    unless game
      return nil
    end
    return team == game.away_team ? game.home_team : game.away_team
  end


  def predict_opposing_lineup
    game_day = game.game_day

    i = 1
    # Iterate through previous games until you find one that the opposing team played a pitcher with the same handedness
    while true
      prev_game_day = game_day.prev_day(i)
      unless prev_game_day
        i += 1
        next
      end

      games = prev_game_day.games.where("away_team_id = #{opp_team.id} OR home_team_id = #{opp_team.id}")

      games.each do |game|

        if game.away_team_id == opp_team.id
          opp_pitcher = game.lancers.find_by(starter: true, team_id: game.home_team_id)
        else
          opp_pitcher = game.lancers.find_by(starter: true, team_id: game.away_team_id)
        end

        if opp_pitcher && opp_pitcher.player.throwhand == throwhand
          lineup = game.batters.where(team_id: opp_team.id, starter: true).order("lineup ASC")
          if game.home_team.league == "NL"
            lineup = lineup[0...-1]
            batter = game.lancers.find_by(starter: true, team_id: opp_team.id).player.create_batter(game_day.season)
            batter.lineup = 9
            lineup << batter
          end
          return lineup
        end
      end

      if prev_game_day.id == 1
        return Batter.none
      end

      i += 1
    end
  end


  def opposing_lineup

    if game
      game.batters.where(team_id: opp_team.id, starter: true).order("lineup ASC")
    end

  end


  def opposing_batters_handedness

    unless game
      return nil
    end

    opp_lineup = self.opposing_lineup
    opp_lineup = self.predict_opposing_lineup if opp_lineup.size == 0

    throwhand = self.throwhand
    same = opp_lineup.select { |batter| batter.bathand == throwhand }.size
    diff = opp_lineup.size - same

    if throwhand == "L"
      return same, diff
    else
      return diff, same
    end

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

  def sort_pitchers
    game.game_day.index
  end

  # Find previous starting games
  def prev_pitchers
    unless game
      return nil
    end
    index = game.game_day.index
    lancers = Lancer.where.not(game_id: nil).where(starter: true, player_id: self.player_id).find_all { |lancer| lancer.game.game_day.index < index }
    lancers = lancers.find_all { |lancer| !lancer.game.game_day.is_preseason? }
    return lancers.sort_by(&:sort_pitchers).reverse
  end


end
