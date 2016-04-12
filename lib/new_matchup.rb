module NewMatchup

  include NewShare

  def check_which_day(time)
  	if time.day == Time.now.day
  	  today = true
  	  date = DateTime.now.to_date
  	elsif time.day == Time.now.tomorrow.day
  	  today = false
  	  date = DateTime.now.tomorrow.to_date
  	end
  	return today, date
  end

  def set_game_info_arrays(doc)
    home = Array.new
	away = Array.new
	gametime = Array.new
	doc.css(".game-time").each do |time|
	  gametime << time.text
	end
	doc.css(".team-name").each_with_index do |stat, index|
	  team = Team.find_by_name(stat.text)
	  if index%2 == 0
	    away << team
	  else
		home << team
	  end
	end
	teams = home + away
	duplicates = teams.select{ |e| teams.count(e) > 1 }.uniq
	return home, away, gametime, duplicates
  end

  def convert_to_local_time(game, time)

    unless colon = time.index(":")
	  return
	end

	eastern_hour = time[0...colon].to_i
	local_hour = eastern_hour + game.home_team.timezone

	period = time[colon..-4]
	if (eastern_hour == 12 && local_hour < 12) || local_hour < 0
	  period[period.index("P")] = "A"
	end

	if local_hour < 1
	  local_hour += 12
	end

	return local_hour.to_s + period

  end

  def reset_starters
  	Player.starters.update_all(starter: false)
  end

  def create_game(game_day, home_team, away_team, num)
  	game = Game.create(game_day_id: game_day.id, home_team_id: home_team.id, away_team_id: away_team.id, num: num)
  	puts game.url + " created"
  end


  def create_games(game_day, gametime, home, away, duplicates, time)
  	days_games = game_day.games
  	preseason = is_preseason?(time)
	# Create games that have not been created yet
	(0...gametime.size).each do |i|
	  games = days_games.where(:home_team_id => home[i].id, :away_team_id => away[i].id)
	  if preseason
		if games.empty?
		  game = create_game(game_day, time, home[i], away[i], '0')
		end
	  else
		# Check for double headers during regular season
		size = games.size
		if size == 1 && duplicates.include?(home[i])
		  game = create_game(game_day, home[i], away[i], '2')
		elsif size == 0 && duplicates.include?(home[i])
		  game = create_game(game_day, home[i], away[i], '1')
		elsif size == 0
		  game = create_game(game_day, home[i], away[i], '0')
		end
	  end

	  if game
	  	game.update_attributes(time: convert_to_local_time(game, gametime[i]))
		puts 'Game ' + game.url + ' created'
	  end
	end
  end

  def element_type(element)
	element_class = element['class']
	case element_class
	when /game-time/
	  type = 'time'
	when /no-lineup/
	  type = 'no lineup'
	when /team-name/
	  type = 'lineup'
	else
	  if element.children.size == 3
		type = 'batter'
	  else
		type = 'pitcher'
	  end
	end
  end

  def find_team_from_pitcher_index(pitcher_index, away_team, home_team)
	if pitcher_index%2 == 0
	  away_team
	else
	  home_team
	end
  end

  def find_team_from_batter_index(batter_index, away_team, home_team, away_lineup, home_lineup)
    if away_lineup && home_lineup
	  if batter_index/9 == 0
		away_team
	  else
	    home_team
	  end
	elsif away_lineup
	  away_team
	else
	  home_team
	end
  end

  def create_game_stats(doc, games)
	game_index = -1
	away_lineup = home_lineup = false
	away_team = home_team = nil
	team_index = pitcher_index = batter_index = 0
	elements = doc.css(".players div, .team-name+ div, .team-name, .game-time")
	elements.each_with_index do |element, index|
	  type = element_type(element)
	  case type
	  when 'time'
		game_index += 1
		batter_index = 0
		next
	  when 'lineup'
		if team_index%2 == 0
		  away_team = Team.find_by_name(element.text)
		  away_lineup = true
		else
		  home_team = Team.find_by_name(element.text)
		  home_lineup = true
		end
		team_index += 1
		next
	  when 'no lineup'
		if team_index%2 == 0
		  away_team = Team.find_by_name(element.text)
		  away_lineup = false
		else
		  home_team = Team.find_by_name(element.text)
		  home_lineup = false
		end
		team_index += 1
		next
	  when 'pitcher'
		# Skip any pitchers that aren't announced
		if element.text == "TBD"
		  pitcher_index += 1
		  next
		else
		  identity, fangraph_id, name, handedness = pitcher_info(element)
		end
		team = find_team_from_pitcher_index(pitcher_index, away_team, home_team)
		player = Player.search(name, identity)
		pitcher_index += 1
	  when 'batter'
		identifier, fangraph_id, name, handedness, lineup, position = batter_info(element)
		team = find_team_from_batter_index(batter_index, away_team, home_team, away_lineup, home_lineup)
		player = Player.search(name, identity)
		batter_index += 1
	  end

	  # Make sure the player is in database, otherwise create him
	  unless player
	  	player = Player.create(name: name, identity: identity, team_id: team.id)
	  	puts "Player " + player.name + " created"
	  end

	  # Set player to starting for later deletion of excess players
	  player.update_attributes(starter: true)

	  game = games.order("id")[game_index]
	  if player
	  	if type == 'pitcher'
		  stats = player.game_pitcher_stats(game)
		elsif type == 'batter'
		  stats = player.game_batter_stats(game)
		  stats.each do |stat|
		  	stat.update_attributes(lineup: lineup, position: position)
		  end
	    end
	    stats.each do |stat|
	      stat.update_attributes(team_id: team.id, starter: true)
	    end
	  end
	end
  end

  def create_tomorrow_stats(doc, games, away, home)
    doc.css(".team-name+ div").each_with_index do |element, index|
	  if element.text == "TBD"
	    next
	  end
	  game = games[index/2]
	  if index%2 == 0
		team = away[index/2]
	  else
		team = home[index/2]
	  end
	  identity, fangraph_id, name, handedness = pitcher_info(element)
	  player = Player.search(name, identity)
	  unless player
	  	player = Player.create(name: name, identity: identity)
	  end
	  player.update_attributes(starter: true)
	  stats = player.game_pitcher_stats(game)
	  stats.each do |stat|
	  	stat.update_attributes(starter: true, team_id: team.id)
	  end
	end
  end

  def create_bullpen(games)
  	games.each do |game|
  	  Player.bullpen.where(team_id: game.home_team_id).each do |player|
  	  	stats = player.game_pitcher_stats(game)
	  	stats.each do |stat|
		  stat.update_attributes(bullpen: true, team_id: game.home_team_id)
		end
  	  end
	  Player.bullpen.where(team_id: game.away_team_id).each do |player|
	  	stats = player.game_pitcher_stats(game)
	  	stats.each do |stat|
		  stat.update_attributes(bullpen: true, team_id: game.away_team_id)
		end
  	  end
  	end
  end

  def remove_excess_starters(games)
  	games.each do |game|
  	  game.pitcher_stats.where(starter: true).each do |pitcher_stat|
  	  	unless pitcher_stat.player.starter
  	  	  pitcher_stat.destroy
  	  	end
  	  end
	  game.pitcher_stats.where(bullpen: true).each do |pitcher_stat|
  	  	unless pitcher_stat.player.bullpen
  	  	  pitcher_stat.destroy
  	  	end
  	  end
  	  game.batter_stats.where(starter: true).each do |batter_stat|
  	  	unless batter_stat.player.starter
  	  	  batter_stat.destroy
  	  	end
  	  end
  	end
  end

  def set_matchups(time)

  	today, date = check_which_day(time)
  	url = "http://www.baseballpress.com/lineups/#{date}"
  	doc = download_document(url)

  	reset_starters

  	game_day = GameDay.search(time)
  	home, away, gametime, duplicates = set_game_info_arrays(doc)
  	create_games(game_day, gametime, home, away, duplicates, time)
  	games = game_day.games

  	if today
  	  create_game_stats(doc, games)
  	  create_bullpen(games)
  	else
  	  create_tomorrow_stats(doc, games, away, home)
  	end

    remove_excess_starters(games)

  end

end