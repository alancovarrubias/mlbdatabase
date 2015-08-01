namespace :testing do

	def findDate(today)
		year = today.year.to_s
		month = today.month.to_s
		day = today.day.to_s
		hour = today.hour

		if month.size == 1
			month = '0' + month
		end
		if day.size == 1
			day = '0' + day
		end
		return hour, day, month, year
	end
	
	task :test => :environment do
		require 'nokogiri'
		require 'open-uri'

		Game.all.each do |game|
			if game.away_money_line == nil
				game.update_attributes(:away_money_line => "")
			end
			if game.home_money_line == nil
				game.update_attributes(:home_money_line => "")
			end
			if game.away_total == nil
				game.update_attributes(:away_total => "")
			end
			if game.home_total == nil
				game.update_attributes(:home_total => "")
			end
		end
		
	end

end