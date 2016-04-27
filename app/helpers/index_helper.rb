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

end
