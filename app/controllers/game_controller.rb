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
	@date = month + ' ' + day
	
	@forecasts = @game.weathers.where(station: "Forecast")
	@weathers = @game.weathers.where(station: "Actual")


	@away_starting_lancer = @game.lancers.where(team_id: @away_team.id, starter: true)
	@home_starting_lancer = @game.lancers.where(team_id: @home_team.id, starter: true)

	@away_batters = @game.batters.where(team_id: @away_team.id).order("lineup")
	@home_batters = @game.batters.where(team_id: @home_team.id).order("lineup")


	unless @away_batters.empty?
	  @away_batters.order("lineup")
	end
	unless @home_batters.empty?
	  @home_batters.order("lineup")
	end

    @home_lefties, @home_righties = get_batters_handedness(@away_starting_lancer.first, @home_batters)
    @away_lefties, @away_righties = get_batters_handedness(@home_starting_lancer.first, @away_batters)

	@away_bullpen_lancers = @game.lancers.where(team_id: @away_team.id, bullpen: true)
	@home_bullpen_lancers = @game.lancers.where(team_id: @home_team.id, bullpen: true)

  end

  def lefty?(throwhand)
    if throwhand == "L"
 	  true
 	else
 	  false
    end
  end


  def team
	@team = Team.find_by_id(params[:id])
	if params[:left] == '1'
	  @left = true
	else
	  @left = false
	end

	if @left
	  @pitchers = @team.pitchers.where(:game_id => nil).order(:IP_L).reverse
	  @hitters = @team.hitters.where(:game_id => nil).order(:AB_L).reverse
	else
	  @pitchers = @team.pitchers.where(:game_id => nil).order(:IP_R).reverse
	  @hitters = @team.hitters.where(:game_id => nil).order(:AB_R).reverse.limit(20)
	end
  end

  def get_previous_lineup(game_day, team, opp_throwhand)
  	while true

  	  game_day = game_day.prev_day(1)

  	  games = game_day.games.where("away_team_id = #{team.id} OR home_team_id = #{team.id}")

  	  games.each do |game|

  	  	if game.away_team_id == team.id
  	  	  opp_pitcher = game.lancers.where(starter: true, team_id: game.home_team_id).first
  	  	else
  		  opp_pitcher = game.lancers.where(starter: true, team_id: game.away_team_id).first
  	  	end

  	  	if opp_pitcher.player.throwhand == opp_throwhand
  	  		return game.batters.where(team_id: team.id, starter: true)
  	  	end
  	  end

	  if game_day.id == 1
  	  	return Array.new
  	  end

    end
  end

  def game_day?(time)
  	hour, day, month, year = find_date(time)
  	if year.to_i == params[:year].to_i && month.to_i == params[:month].to_i && day.to_i == params[:day].to_i
  	  true
  	else
  	  false
  	end
  end

  private

  def get_batters_handedness(lancer, batters)
  	unless lancer
  	  return 0, 0
  	end
    lancer = lancer.player
    batters = batters.map { |batter| batter.player }
    same = diff = 0
    batters.each do |batter|
      if lancer.throwhand == batter.bathand
        same += 1
      else
        diff += 1
      end
    end
    if lancer.throwhand == "R"
      return diff, same
    else
      return same, diff
    end
  end

end
