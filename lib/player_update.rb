module PlayerUpdate

  include NewShare

  def update_pitchers(game_day)
  	games = game_day.games
  	games.each do |game|
  	  puts game.url
  	end
  end


end