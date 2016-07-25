class Lancer < ActiveRecord::Base
  belongs_to :team
  belongs_to :player
  belongs_to :game
  belongs_to :season
  has_many   :pitcher_stats, dependent: :destroy

  def self.starters
    where(game_id: nil, starter: true)
  end

  def self.bullpen
    where(game_id: nil, bullpen: true)
  end

  def name
    player.name
  end

  def identity
    player.identity
  end

  def stats(handedness=nil)
  	if pitcher_stats.size == 0
  	  PitcherStat.create(lancer: self, range: "Season", handedness: "L")
      PitcherStat.create(lancer: self, range: "Season", handedness: "R")
      PitcherStat.create(lancer: self, range: "30 Days", handedness: "")
  	end
    unless handedness
      pitcher_stats
    else
      pitcher_stats.find_by(handedness: handedness)
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
    if game
      team == game.away_team ? game.home_team : game.away_team
    else
    end
  end


  def view_stats(seasons)
    stat_array = Array.new
    stat_array << self.stats
    seasons.each do |season|
      unless self.season == season
        stat_array << player.create_lancer(season).stats
      end
    end
    return stat_array
  end


  def predict_opposing_lineup
    game_day = game.game_day

    i = 1
    # Iterate through previous games until you find one that the opposing team played a pitcher with the same handedness
    while true
      prev_game_day = game_day.previous_days(i)
      unless prev_game_day
        i += 1
        next
      end

      games = prev_game_day.games.includes(:lancers, :batters).where("away_team_id = #{opp_team.id} OR home_team_id = #{opp_team.id}")

      games.each do |game|

        if game.away_team_id == opp_team.id
          opp_pitcher = game.lancers.find_by(starter: true, team_id: game.home_team_id)
        else
          opp_pitcher = game.lancers.find_by(starter: true, team_id: game.away_team_id)
        end

        if opp_pitcher && opp_pitcher.player.throwhand == throwhand
          puts game.id
          puts "WHOOO"
          lineup = game.batters.where(team: opp_team, starter: true).order("lineup ASC")
          next unless lineup.size == 9
          if game.home_team.league == "NL"
            lineup = lineup[0...-1]
            puts game.id
            lancer = game.lancers.find_by(starter: true, team: opp_team)
            if lancer
              batter = lancer.player.create_batter(game_day.season)
              batter.lineup = 9
              lineup << batter
            end
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
      game.batters.where(team: opp_team, starter: true).order("lineup ASC")
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
      game_day = self.game.game_day.previous_days(days)
      unless game_day
        next
      end
      game_ids = game_day.games.map { |game| game.id }
      lancer = Lancer.find_by(player: self.player, game_id: game_ids)

      if lancer
        count += lancer.pitches * 10 ** num_size[index]
      end
    end

    return count

  end

  def prev_bullpen_pitches(days)

    unless game
      return nil
    end
    prev_game_day = game.game_day.previous_days(days)
    unless prev_game_day
      return 0
    end
    games = prev_game_day.games
    lancer = Lancer.find_by(player: player, game: games)
    lancer ? lancer.pitches : 0
    
  end

  def prev_pitchers
    Lancer.includes(game: :game_day)
    .where.not(game: nil)
    .where(player: player, starter: true)
    .where("game_days.date < ?", game.game_day.date)
    .order("game_days.date DESC")
  end

  def self.add_innings
    ip_array = all.map {|pitcher| pitcher.ip}
    sum = 0
    decimal = 0
    ip_array.each do |i|
      decimal += i.modulo(1)
      sum += i.to_i
    end
    thirds = (decimal*10).to_i
    sum += thirds/3
    return sum += (thirds%3).to_f/10
  end


end
