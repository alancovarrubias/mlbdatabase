module Create

  class Games

    def create(season, team)
      url = "http://www.baseball-reference.com/teams/#{team.abbr}/#{season.year}-schedule-scores.shtml"
      puts url
      doc = Nokogiri::HTML(open(url))
      year = season.year
      month = day = num = away_team = home_team = home = href = nil
      game_params = Hash.new
      doc.css("#team_schedule td").each_with_index do |game, index|
        case index%21
        when 2
          href = game.child['href']
          break unless href
          month, day, num = get_game_date(game)
          game_day = GameDay.search(Date.new(year, month, day))
          game_params[:game_day] = game_day
          game_params[:num] = num
        when 4
          home_team = Team.find_by_abbr(game.text)
        when 5
          home = ishome?(game)
        when 6
          away_team = Team.find_by_abbr(game.text)
          away_team, home_team = get_correct_teams(home, away_team, home_team)
          game_params[:away_team_id] = away_team.id
          game_params[:home_team_id] = home_team.id
          if href
            unless Game.find_by(game_params)
              game = Game.create(game_params)
              puts "#{game.url} created"
            end
          end
        end
      end
    end


    private

      def ishome?(game)
        if game.text.size == 1
          false
        else
          true
        end
      end

      def get_game_date(game)
        if game.children.size == 1
          num = "0"
        else
          num = game.text[-2]
        end
        href = game.child['href']
        if href
          month = href[31..32].to_i
          day = href[34..35].to_i
        end
        return month, day, num
      end

      def get_correct_teams(home, away_team, home_team)
        unless home
          temp = away_team
          away_team = home_team
          home_team = temp
        end
        return away_team, home_team
      end

  end

end