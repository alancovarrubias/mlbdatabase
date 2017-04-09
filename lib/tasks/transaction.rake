namespace :transaction do

  task create: :environment do

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

  	include NewShare
    Season.where(year: 2017).each do |season|
      game_days = season.game_days
      (1..4).each do |month|
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
              unless game_day = game_days.find_by(month: month, day: day)
                game_day = GameDay.create(season_id: season.id, year: season.year, month: month, day: day)
              end
            when 1
              transaction(element, game_day)
            end
          end
        end
      end
    end

  end

  task active: :environment do
    time = Time.new(2016, 1, 1)
    while true
      game_day = GameDay.search(time)
      game_day.transactions.each do |transaction|
        
      end
      time = time.tomorrow
    end
  end

end
