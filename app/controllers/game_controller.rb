class GameController < ApplicationController
  include NewShare
  require 'date'

  def new

  	@game = Game.find_by_id(params[:id])
    @game_day = @game.game_day
    @season = @game_day.season

	  @away_team = @game.away_team
	  @home_team = @game.home_team
	  @image_url = @home_team.id.to_s + ".png"

	  month = Date::MONTHNAMES[@game_day.month]
	  day = @game_day.day.to_s
	  @date = "#{month} #{day}"
	
	  @forecasts = @game.weathers.where(station: "Forecast")
	  @weathers = @game.weathers.where(station: "Actual")


	  @away_starting_lancer = @game.lancers.where(team_id: @away_team.id, starter: true)
	  @home_starting_lancer = @game.lancers.where(team_id: @home_team.id, starter: true)

	  @away_batters = @game.batters.where(team_id: @away_team.id)
	  @home_batters = @game.batters.where(team_id: @home_team.id)

    # True if batters are facing a lefty or a righty
    @away_left = @home_starting_lancer.first.player.throwhand == "L"
    @home_left = @away_starting_lancer.first.player.throwhand == "L"

    league = @home_team.league

    if @away_batters.empty? && !@away_starting_lancer.empty?
      @away_predicted = "Predicted "
      @away_batters = predict_lineup(@game_day, @away_team, @away_starting_lancer.first.player.throwhand)
    end

    if @home_batters.empty? && !@home_starting_lancer.empty?
      @home_predicted = "Predicted "
      @home_batters = predict_lineup(@game_day, @home_team, @home_starting_lancer.first.player.throwhand)
    end

    @away_batters = @away_batters.order("lineup ASC")
    @home_batters = @home_batters.order("lineup ASC")

    if @away_predicted && league == "NL"
      @away_batters = @away_batters[0...-1]
      batter = @away_starting_lancer.first.player.create_batter(@season)
      batter.lineup = 9
      @away_batters << batter
    end

    if @home_predicted && league == "NL"
      @home_batters = @home_batters[0...-1]
      batter = @home_starting_lancer.first.player.create_batter(@season)
      batter.lineup = 9
      @home_batters << batter
    end

	  @away_bullpen_lancers = @game.lancers.where(team_id: @away_team.id, bullpen: true)
	  @home_bullpen_lancers = @game.lancers.where(team_id: @home_team.id, bullpen: true)

  end

  def team
	  @team = Team.find_by_id(params[:id])
	  if params[:left] == '1'
	    @left = true
	  else
	    @left = false
	  end
  end

  def predict_lineup(game_day, team, opp_throwhand)

    i = 1
  	while true

  	  prev_game_day = game_day.prev_day(i)

      logger.debug "GameDay ID #{game_day.id}"

      unless prev_game_day
        i += 1
        next
      end

  	  games = prev_game_day.games.where("away_team_id = #{team.id} OR home_team_id = #{team.id}")

  	  games.each do |game|

  	  	if game.away_team_id == team.id
  	  	  opp_pitcher = game.lancers.find_by(starter: true, team_id: game.home_team_id)
  	  	else
  		    opp_pitcher = game.lancers.find_by(starter: true, team_id: game.away_team_id)
  	  	end

  	  	if opp_pitcher.player.throwhand == opp_throwhand
  	  		return game.batters.where(team_id: team.id, starter: true)
  	  	end
  	  end

  	  if prev_game_day.id == 1
    	  	return nonea
  	  end

      i += 1

    end
  end



end
