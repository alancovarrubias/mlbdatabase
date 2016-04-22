module GameUpdate

  include NewShare

  def fix_abbr(abbr)
    case abbr
    when "TB"
      "TBR"
    when "SF"
      "SFG"
    when "SD"
      "SDP"
    when "CWS"
      "CHW"
    when "KC"
      "KCR"
    when "WSH"
      "WSN"
    else
      abbr
    end
  end

  def add_game_to_array(game_array, day_games, team)
  	unless team
  	  game_array << nil
  	  return
  	end
  	games = day_games.where(home_team_id: team.id)
    if games.size == 2
      if game_array.include?(games.first)
        game_array << games.second
      else
        game_array << games.first
      end
    elsif games.size == 1
      game_array << games.first
    else
      game_array << nil
    end  
  end

  def closingline

    game_day = GameDay.search(Time.now)
    day_games = game_day.games
    game_size = day_games.size
    hour, day, month, year = find_date(Time.now)
    date_url = "?date=%d%02d%02d" % [year, month, day]
    url = "http://www.sportsbookreview.com/betting-odds/mlb-baseball/#{date_url}"
    puts url
    doc = Nokogiri::HTML(open(url))
    game_array = Array.new
    doc.css(".team-name a").each_with_index do |stat, index|
      # Break once we find the all teams playing today
      if index == game_size*2
        break
      end
      if index%2 == 1
        abbr = stat.child.text[0...-3].to_s
        abbr = fix_abbr(abbr)
        team = Team.find_by_abbr(abbr)
        add_game_to_array(game_array, day_games, team)   
      end
    end

    away_money_line = Array.new
    home_money_line = Array.new
    doc.css(".eventLine-consensus+ .eventLine-book b").each_with_index do |stat, index|
      if index == game_size*2
        break
      end
      if index%2 == 0
        away_money_line << stat.text
      else
        home_money_line << stat.text
      end
    end

    away_totals = Array.new
    home_totals = Array.new
    url = "http://www.sportsbookreview.com/betting-odds/mlb-baseball/totals/" + date_url
    doc = Nokogiri::HTML(open(url))
    doc.css(".eventLine-consensus+ .eventLine-book b").each_with_index do |stat, index|
      if index == game_size*2
        break
      end
      if index%2 == 0
        away_totals << stat.text
      else
        home_totals << stat.text
      end
    end

    (0...game_size).each do |i|
      game = game_array[i]
      if game
        puts game.url
        game.update(away_money_line: away_money_line[i], home_money_line: home_money_line[i], away_total: away_totals[i], home_total: home_totals[i])
      end
    end

  end




  def find_team_name(team_id)
    case team_id
    when /ANGELS/
      "Angels"
    when /HOUSTON/
      "Astros"
    when /OAKLAND/
       "Athletics"
    when /TORONTO/
       "Blue Jays"
    when /ATLANTA/
       "Braves"
    when /MILWAUKEE/
       "Brewers"
    when /LOUIS/
       "Cardinals"
    when /CUBS/
       "Cubs"
    when /ARIZONA/
       "Diamondbacks"
    when /DODGERS/
       "Dodgers"
    when /FRANCISCO/
       "Giants"
    when /CLEVELAND/
       "Indians"
    when /SEATTLE/
       "Mariners"
    when /MIAMI/
       "Marlins"
    when /METS/
       "Mets"
    when /WASHINGTON/
       "Nationals"
    when /BALTIMORE/
       "Orioles"
    when /DIEGO/
       "Padres"
    when /PHILADELPHIA/
       "Phillies"
    when /PITTSBURGH/
       "Pirates"
    when /TEXAS/
       "Rangers"
    when /TAMPA/
       "Rays"
    when /BOSTON/
       "Red Sox"
    when /CINCINATTI/
       "Reds"
    when /COLORADO/
       "Rockies"
    when /KANSAS/
       "Royals"
    when /DETROIT/
       "Tigers"
    when /MINNESOTA/
       "Twins"
    when /WHITE/
       "White Sox"
    when /YANKEES/
       "Yankees"
    else
       "Not found"
    end
  end




  def set_umpire
    url = "http://www.statfox.com/mlb/umpiremain.asp"
    doc = download_document(url)
    games = GameDay.search(Time.now).games
    team_id = var = 0
    team = nil
    doc.css(".datatable a").each do |data|
      var += 1
      if var%3 == 2
        team_id = data['href']
      elsif var%3 == 0
        if data.text.size == 3
          var = 1
          next
        end
        ump = data.text
        team_name = find_team_name(team_id)
        if team = Team.find_by_name(team_name)
          game = games.find_by(home_team_id: team.id)
          game.update(ump: ump)
          puts "#{game.url} #{ump}"
        end
      end
    end
  end


end