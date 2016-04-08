module Matchup

  include Share

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

  def convert_to_local_time_and_add_to_game(game, time)

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

	game.update_attributes(time: local_hour.to_s + period)

  end

  def create_game(time, home_team, away_team, num)
  	hour, day, month, year = find_date(time)
  	Game.create(year: year, month: month, day: day, home_team_id: home_team.id, away_team_id: away_team.id, num: num)
  end

  def create_games(days_games, gametime, home, away, duplicates, time)
	hour, day, month, year = find_date(time)
	# Create games that have not been created yet
	(0...gametime.size).each do |i|
	  games = days_games.where(:home_team_id => home[i].id, :away_team_id => away[i].id)
	  if is_preseason?(time)
		if games.empty?
		  game = create_game(time, home[i], away[i], '0')
		end
	  else
		# Check for double headers during regular season
		size = games.size
		if size == 1 && duplicates.include?(home[i])
		  game = create_game(time, home[i], away[i], '2')
		elsif size == 0 && duplicates.include?(home[i])
		  game = create_game(time, home[i], away[i], '1')
		elsif size == 0
		  game = create_game(time, home[i], away[i], '0')
		end
	  end

	  if game
	  	convert_to_local_time_and_add_to_game(game, gametime[i])
		puts 'Game ' + game.url + ' created'
	  end
	end
  end

  def set_starters_false(today)
  	if today
  	  Pitcher.starting_pitchers.update_all(starter: false)
  	  Hitter.starting_hitters.update_all(starter: false, lineup: 0)
  	else
  	  Pitcher.tomorrow_starting_pitchers.update_all(tomorrow_starter: false)
  	end
  end

  def set_matchups(time)

  	today, date = check_which_day(time)

  	url = "http://www.baseballpress.com/lineups/#{date}"
  	doc = download_document(url)

  	home, away, gametime, duplicates = set_game_info_arrays(doc)
  	days_games = Game.days_games(time)
  	create_games(days_games, gametime, home, away, duplicates, time)
  	days_games = Game.days_games(time)

  	set_starters_false(today)

  	if today
  	  create_game_starters(doc, days_games)
	  create_bullpen_pitchers(days_games, Pitcher.proto_pitchers, Hitter.proto_hitters)
	  remove_excess_starters(days_games, Pitcher.proto_pitchers, Hitter.proto_hitters)
  	else
  	  set_tomorrow_starters(doc, Pitcher.proto_pitchers, away, home)
  	end

  end

  def set_tomorrow_starters(doc, proto_pitchers, away, home)
    doc.css(".team-name+ div").each_with_index do |element, index|
	  if element.text == "TBD"
	    next
	  end
	  if index%2 == 0
		team = away[index/2]
	  else
		team = home[index/2]
	  end
	  identifier, fangraph_id, name, handedness = pitcher_info(element)
	  pitcher = find_player(proto_pitchers, identifier, fangraph_id, name)
	  unless pitcher
		pitcher = Pitcher.create(:game_id => nil, :team_id => team.id, :tomorrow_starter => true, :name => name, :alias => identifier, :fangraph_id => fangraph_id, :throwhand => handedness)
	  else
		pitcher.update_attributes(:team_id => team.id, :tomorrow_starter => true, :name => name, :alias => identifier, :fangraph_id => fangraph_id, :throwhand => handedness)
	  end
	end
  end


  def find_pitcher_team(pitcher_index, away_team, home_team)
	if pitcher_index%2 == 0
	  away_team
	else
	  home_team
	end
  end

  def hitter_info(element)
	name = element.children[1].text
	lineup = element.child.to_s[0]
	handedness = element.children[2].to_s[2]
	position = element.children[2].to_s.match(/\w*$/).to_s
	identifier = element.children[1]['data-bref']
	fangraph_id = element.children[1]['data-razz'].gsub!(/[^0-9]/, "")
	return identifier, fangraph_id, name, handedness, lineup, position
  end

  def find_hitter_team(hitter_index, away_team, home_team, away_lineup, home_lineup)
    if away_lineup && home_lineup
	  if hitter_index/9 == 0
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

  def create_game_pitcher(pitcher, game)
	unless game_pitcher = Pitcher.where(:game_id => game.id, :name => pitcher.name).first
	  new_pitcher = pitcher.dup
	  new_pitcher.game_id = game.id
	  new_pitcher.save
	end
  end

  def create_game_hitter(hitter, game)
	unless game_hitter = Hitter.where(:game_id => game.id, :name => hitter.name).first
	  new_hitter = hitter.dup
	  new_hitter.game_id = game.id
	  new_hitter.save
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
		type = 'hitter'
	  else
		type = 'pitcher'
	  end
	end
  end


	def create_game_starters(doc, games)
		game_index = -1
		away_lineup = home_lineup = false
		away_team = home_team = nil
		team_index = pitcher_index = hitter_index = 0
		elements = doc.css(".players div, .team-name+ div, .team-name, .game-time")
		elements.each_with_index do |element, index|
			type = element_type(element)
			case type
			when 'time'
				game_index += 1
				hitter_index = 0
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
				proto_pitchers = Pitcher.where(:game_id => nil)
				# Skip any pitchers that aren't announced, otherwise find the prototype pitcher
				if element.text == "TBD"
					pitcher_index += 1
					next
				else
					identifier, fangraph_id, name, handedness = pitcher_info(element)
					pitcher = find_player(proto_pitchers, identifier, fangraph_id, name)
				end
				team = find_pitcher_team(pitcher_index, away_team, home_team)
				# If prototype pitcher not found, create one
				unless pitcher
					pitcher = Pitcher.create(:game_id => nil, :team_id => team.id, :starter => true, :name => name, :alias => identifier, :fangraph_id => fangraph_id, :throwhand => handedness)
				else
					pitcher.update_attributes(:team_id => team.id, :starter => true, :name => name, :alias => identifier, :fangraph_id => fangraph_id, :throwhand => handedness)
				end
				pitcher_index += 1
			when 'hitter'
				proto_hitters = Hitter.where(:game_id => nil)
				# look for the prototype hitter
				identifier, fangraph_id, name, handedness, lineup, position = hitter_info(element)
				hitter = (proto_hitters, identifier, fangraph_id, name)
				team = find_hitter_team(hitter_index, away_team, home_team, away_lineup, home_lineup)
				# If prototype hitter not found, create one
				unless hitter
					hitter = Hitter.create(:game_id => nil, :team_id => team.id, :starter => true, :name => name, :alias => identifier, :fangraph_id => fangraph_id, :bathand => handedness, :lineup => lineup)
				else
					hitter.update_attributes(:team_id => team.id, :starter => true, :name => name, :alias => identifier, :fangraph_id => fangraph_id, :bathand => handedness, :lineup => lineup)
				end
				hitter_index += 1
			end

			game = games.order("id")[game_index]
			if pitcher
				create_game_pitcher(pitcher, game)
			end
			if hitter
				create_game_hitter(hitter, game)
			end
		end
	end

  def create_bullpen_pitchers(todays_games, proto_pitchers, proto_hitters) 
	# Create bullpen pitchers and delete extra players
	proto_bullpen_pitchers = proto_pitchers.where(:bullpen => true)
	todays_games.each do |game|
		
	  game_pitchers = Pitcher.where(:game_id => game.id)

	  game_bullpen_pitchers = proto_bullpen_pitchers.where(:team_id => game.home_team.id) + proto_bullpen_pitchers.where(:team_id => game.away_team.id)

	  game_bullpen_pitchers.each do |pitcher|
		unless game_pitchers.find_by_alias(pitcher.alias)
		  new_pitcher = pitcher.dup
		  new_pitcher.game_id = game.id
		  new_pitcher.save
		end
	  end
	end
  end

	# Remove any pitchers that weren't starters this iteration
	def remove_excess_starters(todays_games, proto_pitchers, proto_hitters)
		todays_games.each do |game|
			game_hitters = Hitter.where(:game_id => game.id)
			game_pitchers = Pitcher.where(:game_id => game.id)

			starting_hitters = game_hitters.where(:starter => true)
			starting_hitters.each do |hitter|
				unless proto_hitters.find_by_alias(hitter.alias).starter
					unless proto_hitters.find_by_name(hitter.name).starter
						hitter.destroy
						puts hitter.name + ' destroyed'
					end
				end
			end

			starting_pitchers = game_pitchers.where(:starter => true)
			starting_pitchers.each do |pitcher|
				unless proto_pitchers.find_by_alias(pitcher.alias).starter
					unless proto_pitchers.find_by_name(pitcher.name).starter
						pitcher.destroy
						puts pitcher.name + ' destroyed'
					end
				end
			end
		end
	end

	def set_umpire(doc)
		hour, day, month, year = find_date(Time.now)
		if hour.to_i > 4 && hour.to_i < 20
			if month.size == 1
				month = "0" + month
			end
			if day.size == 1
				day = "0" + day
			end
			id = var = 0
			team = nil
			doc.css(".datatable a").each do |data|
				var += 1
				if var%3 == 2
					id = data['href']
				elsif var%3 == 0
					if data.text.size == 3
						var = 1
						next
					end
					ump = data.text
					case id
					when /ANGELS/
						team = "Angels"
					when /HOUSTON/
						team = "Astros"
					when /OAKLAND/
						team = "Athletics"
					when /TORONTO/
						team = "Blue Jays"
					when /ATLANTA/
						team = "Braves"
					when /MILWAUKEE/
						team = "Brewers"
					when /LOUIS/
						team = "Cardinals"
					when /CUBS/
						team = "Cubs"
					when /ARIZONA/
						team = "Diamondbacks"
					when /DODGERS/
						team = "Dodgers"
					when /FRANCISCO/
						team = "Giants"
					when /CLEVELAND/
						team = "Indians"
					when /SEATTLE/
						team = "Mariners"
					when /MIAMI/
						team = "Marlins"
					when /METS/
						team = "Mets"
					when /WASHINGTON/
						team = "Nationals"
					when /BALTIMORE/
						team = "Orioles"
					when /DIEGO/
						team = "Padres"
					when /PHILADELPHIA/
						team = "Phillies"
					when /PITTSBURGH/
						team = "Pirates"
					when /TEXAS/
						team = "Rangers"
					when /TAMPA/
						team = "Rays"
					when /BOSTON/
						team = "Red Sox"
					when /CINCINATTI/
						team = "Reds"
					when /COLORADO/
						team = "Rockies"
					when /KANSAS/
						team = "Royals"
					when /DETROIT/
						team = "Tigers"
					when /MINNESOTA/
						team = "Twins"
					when /WHITE/
						team = "White Sox"
					when /YANKEES/
						team = "Yankees"
					else
						team = "Not found"
					end
					if team = Team.find_by_name(team)
						puts ump
						puts team.name
						Game.where(:year => year, :month => month, :day => day, :home_team_id => team.id).first.update_attributes(:ump => ump)
					end
				end
			end
		end
	end

end