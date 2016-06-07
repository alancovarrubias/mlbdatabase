module Update
  class LocalHour

    include NewShare

    def update(game_day)
      date = game_day.date
      @games = game_day.games
      @home_teams = Array.new
      url = "http://www.baseballpress.com/lineups/%d-%02d-%02d" % [date.year, date.month, date.day]
      doc = download_document(url)
      home_team = away_team = hour = nil
      doc.css(".team-name, .game-time").each_with_index do |stat, index|
        case index%3
        when 0
          if stat.text.include?(":")
            hour = get_hour(stat.text)
          else
            hour = nil
          end
        when 1
          away_team = Team.find_by_name(stat.text)
        when 2
          home_team = Team.find_by_name(stat.text)
          home_team = check_exceptions(game_day, away_team, home_team)
          next unless home_team && hour
          game = get_game(home_team)
          hour = hour + home_team.timezone
          if game
            puts home_team.name
            puts "#{game.url} #{hour}"
            game.update(local_hour: hour)
          end
        end
      end
    end

    private

      def check_exceptions(game_day, away_team, home_team)
        date = game_day.date
        if date.year == 2015 && date.month == 5 && (date.day == 2 || date.day == 1 || date.day == 3)
          if home_team.name == "Orioles"
            away_team
          else
            home_team
          end
        else
          home_team
        end
      end

      def get_hour(text)
        hour = text[0...text.index(":")].to_i
        hour += 12 if text[-5..-4] == "PM" && hour != 12
        return hour
      end

      def get_game(home_team)
        home_team_games = @games.where(home_team: home_team)
        if home_team_games.size == 2
          if @home_teams.include?(home_team)
            home_team_games.find_by(num: "2")
          else
            @home_teams << home_team
            home_team_games.find_by(num: "1")
          end
        else
          home_team_games.first
        end
      end

  end
end