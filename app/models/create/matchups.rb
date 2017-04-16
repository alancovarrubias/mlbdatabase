module Create
  class Matchups

    include NewShare
    
    def create(game_day)
      url = "http://www.baseballpress.com/lineups/%d-%02d-%02d" % [game_day.year, game_day.month, game_day.day]
      doc = download_document(url)
      puts url
      create_games(doc, game_day)
      set_starters_false
      create_game_stats(doc, game_day)
      remove_excess_starters(game_day)
    end

    private

      def set_starters_false
        Batter.starters.update_all(starter: false)
        Lancer.starters.update_all(starter: false)
      end

      def set_game_info_arrays(doc)
        home = Array.new
        away = Array.new
        gametime = Array.new
        # Fill array with game times
        doc.css(".game-time").each do |time|
          gametime << time.text
        end
        # Fill arrays with teams playing
        doc.css(".team-name").each_with_index do |stat, index|
          team = Team.find_by_name(stat.text)
          if index%2 == 0
            away << team
          else
            home << team
          end
        end
        # Find any teams playing double headers
        teams = home + away
        duplicates = teams.select{ |e| teams.count(e) > 1 }.uniq
        return home, away, gametime, duplicates
      end

      def create_game(game_day, home_team, away_team, num, time_order)
        Game.create(game_day: game_day, home_team: home_team, away_team: away_team, num: num, time_order: time_order)
      end

      def convert_to_local_time(game, time)
        unless colon = time.index(":")
          return time
        end
        eastern_hour = time[0...colon].to_i
        local_hour = eastern_hour + game.home_team.timezone
        period = time[colon..-4]

        if (eastern_hour == 12 && local_hour < 12) || local_hour < 0
          period[period.index("P")] = "A"
        end

        # Add twelve hours to local time if hour makes no sense
        if local_hour < 1
          local_hour += 12
        end

        return local_hour.to_s + period
      end

      def create_games(doc, game_day)
        home, away, gametime, duplicates = set_game_info_arrays(doc)
        ball_games = game_day.games
        # Create games that have not been created yet
        (0...gametime.size).each do |i|
          games = ball_games.where(home_team: home[i], away_team: away[i])
          if game_day.is_preseason?
            if games.empty?
              new_game = create_game(game_day, home[i], away[i], '0', i)
            end
          else
            size = games.size
            if size == 1 && duplicates.include?(home[i])
              new_game = create_game(game_day, home[i], away[i], '2', i)
            elsif size == 0 && duplicates.include?(home[i])
              new_game = create_game(game_day, home[i], away[i], '1', i)
            elsif size == 0
              new_game = create_game(game_day, home[i], away[i], '0', i)
            end
          end

          if new_game
            new_game.update_attributes(time: convert_to_local_time(new_game, gametime[i]))
            puts 'Game ' + new_game.url + ' created'
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

      def create_game_stats(doc, game_day)
        games = game_day.games
        game_index = -1
        away_lineup = home_lineup = false
        away_team = home_team = nil
        team_index = pitcher_index = batter_index = 0
        elements = doc.css(".players div, .team-name+ div, .team-name, .game-time")
        season = Season.find_by_year(game_day.year)
        teams = Set.new
        elements.each_with_index do |element, index|
          type = element_type(element)
          case type
          when 'time'
            game_index += 1
            batter_index = 0
            teams << away_team if away_team
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
            if element.text == "TBD"
              pitcher_index += 1
              next
            else
              identity, fangraph_id, name, handedness = pitcher_info(element)
            end
            team = find_team_from_pitcher_index(pitcher_index, away_team, home_team)
            pitcher_index += 1
          when 'batter'
            identity, fangraph_id, name, handedness, lineup, position = batter_info(element)
            team = find_team_from_batter_index(batter_index, away_team, home_team, away_lineup, home_lineup)
            batter_index += 1
          end

          player = Player.search(name, identity)

          # Make sure the player is in database, otherwise create him
          unless player
            if type == 'pitcher'
              player = Player.create(name: name, identity: identity, throwhand: handedness)
            else
              player = Player.create(name: name, identity: identity, bathand: handedness)
            end
            puts "Player " + player.name + " created"
          end


          player.update(team: team)
          game = find_game(games, away_team, teams)

          # Set the season player and the game player to true
          # This will help in determining whether or not to delete a player
          if type == 'pitcher'
            lancer = player.create_lancer(season)
            lancer.update_attributes(starter: true)
            game_lancer = player.create_lancer(season, team, game)
            game_lancer.update(starter: true)
          elsif type == 'batter'
            batter = player.create_batter(season)
            batter.update(starter: true)
            game_batter = player.create_batter(season, team, game)
            game_batter.update(starter: true, position: position, lineup: lineup)
          end
        end
      end

      def find_game(games, away_team, teams)
        games = games.where(away_team: away_team)
        size = games.size
        if size == 1
          return games.first
        elsif size == 2
          return teams.include?(away_team) ? games.second : games.first
        end
      end


      def remove_excess_starters(game_day)
        game_day.games.each do |game|
          game.lancers.where(starter: true).each do |game_lancer|
            lancer = game_lancer.player.find_lancer(game_lancer.season)
            unless lancer.starter
              game_lancer.destroy
            end
          end
          game.batters.where(starter: true).each do |game_batter|
            batter = game_batter.player.find_batter(game_batter.season)
            unless batter.starter
              game_batter.destroy
            end
          end
        end
      end

  end
end
