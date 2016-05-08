module Create
  class Bullpen

    include NewShare

    def create(game_day)
      set_bullpen(game_day)
      create_bullpen(game_day)
    end

    private

      @@bullpen_teams = [1, 2, 3, 4, 12, 13, 17, 21, 22, 23, 26, 27, 28, 29, 30, 5, 6, 7, 8, 9, 10, 11, 14, 15, 16, 18, 19, 20, 24, 25]

      def set_bullpen(game_day)
        url = "http://www.baseballpress.com/bullpenusage/%d-%02d-%02d" % [game_day.year, game_day.month, game_day.day]
        puts url
        doc = download_document(url)

        Lancer.bullpen.update_all(bullpen: false)
        player = nil
        var = one = two = three = 0
        team_index = -1
        season = game_day.season
        doc.css(".league td").each do |element|
          text = element.text
          if text == "Pitcher"
            team_index += 1
          end
          case var
          when 1
            one = get_pitches(text)
            var += 1
          when 2
            two = get_pitches(text)
            var += 1
          when 3
            three = get_pitches(text)
            update_bullpen_pitches(player, one, two, three, game_day.time)
            var = 0
          end

          if element.children.size == 2
            identity, fangraph_id, name, handedness = pitcher_info(element)
            player = Player.search(name, identity, fangraph_id)
            unless player
              player = Player.create(name: name, identity: identity, throwhand: handedness)
            end
            player.update(team_id: @@bullpen_teams[team_index])
            lancer = player.create_lancer(season)
            lancer.update(bullpen: true)
            var = 1
          end
        end
      end

      def create_bullpen(game_day)
        games = game_day.games
        Lancer.bullpen.each do |lancer|
          player = lancer.player
          team = player.team
          if team
            games.where("away_team_id = #{team.id} OR home_team_id = #{team.id}").each do |game|
              lancer = player.create_lancer(lancer.season, team, game)
              lancer.update(bullpen: true)
            end
          end
        end
      end

      def get_pitches(text)
        if text == "N/G"
          return 0
        else
          return text.to_i
        end
      end

      def update_bullpen_pitches(player, one, two, three, time)
        (1..3).each do |n|
          game_day = GameDay.search(time)
          time = time.yesterday
          case n
          when 1
            pitches = one
          when 2
            pitches = two
          when 3
            pitches = three
          end
          lancers = player.game_day_lancers(game_day)
          lancers.each do |lancer|
            lancer.update(pitches: pitches)
          end
        end
      end

  end
end