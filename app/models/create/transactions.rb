module Create
  class Transactions

    include NewShare

    def create(season)
      game_days = season.game_days
      (1..12).each do |month|
        Team.all.each do |team|
          name = get_name(team)
          url = "http://m.#{name}.mlb.com/roster/transactions/%d/%02d" % [season.year, month]
          puts url
          doc = download_document(url)
          game_day = nil
          doc.css("td").each_with_index do |element, index|
            case index%2
            when 0
              month, day = month_day(name, element)
              game_day = game_days.find_by(month: month, day: day)
            when 1
              unless game_day
                transaction(element, game_day)
              end
            end
          end
        end
      end
    end

    private

      def get_name(team)
        name = team.name.downcase.gsub(/\s+/, "")
        if name == "diamondbacks"
          name = "dbacks"
        end
        return name
      end

      def month_day(name, element)
        text = element.text[0...-3]
        index = text.index("/")
        month = text[0...index].to_i
        day = text[index+1..-1].to_i
        if name == "bluejays"
          temp = day
          day = month
          month = temp
        end
        return month, day
      end

      def transaction(element, game_day)
        if element.children.size == 3
          desc = element.text
          name = element.children[1].text
          unless player = Player.find_by_name(name)
            player = Player.create(name: name)
          end
          unless game_day.transactions.find_by(desc: desc, player_id: player.id)
            Transaction.create(game_day_id: game_day.id, player_id: player.id, desc: desc)
          end
        end
      end

  end
end