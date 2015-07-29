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

		
		
	end

end