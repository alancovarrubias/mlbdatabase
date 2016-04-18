module IndexHelper

  def num_string(num)
  	if num == "0"
  	  ''
  	else
  	  " (" + num + ")"
  	end
  end

  def game_link(game)
  	game.away_team.name + " @ " + game.home_team.name + num_string(game.num)
  end

  def find_pitcher(game, away)
    if away
      team = game.away_team
    else
      team = game.home_team
    end
    return game.lancers.find_by(starter: true, team_id: team.id)
  end

  def find_weather(game)
    return game.weathers.find_by(hour: 1, station: "Forecast")
  end

end
