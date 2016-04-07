module Weather


  require 'mechanize'
  require 'Nokogiri'
  require 'open-uri'





  def testing

  	url = ""





  end

















































  	def update_weather_forecast(today)
		require 'open_uri_redirections'

		def convert_to_fahr(celsius)
			symbol = celsius[-1]
			celsius = celsius[0...-1].to_f
			fahr = (celsius * 9.0 / 5.0 + 32.0).round.to_s
			fahr += symbol
			return fahr
		end

		def row(row, text)
			case row
			when 2
				@temperature << text
			when 4
				@humidity << text
			when 6
				@precipitation << text
			when 10
				@wind << text
			end	
		end

		home_team = self.home_team
		time = self.time
		amorpm = time[-2..-1]
		unless time.include?(":")
			return
		end
		time = time[0..time.index(":")].to_i
		if amorpm == "PM" && time != 12
			time += 12
		end
		unless today
			time += 24
		end
		url = @@yahoo_urls[home_team.id-1]
		puts url
		begin
			doc = Nokogiri::HTML(open(url, :allow_redirections => :safe))
		rescue RuntimeError => e
			puts e
			return
		end
		pressure = nil
		doc.css(".second").each_with_index do |weather, index|
			if index == 2
				pressure = weather.text[0..4] + ' in'
				break
			end
		end
		self.update_attributes(:pressure_1 => pressure, :pressure_2 => pressure, :pressure_3 => pressure)

		url = @@accuweather_urls[home_team.id-1]
		url += "?hour=#{time}"
		puts url
		doc = Nokogiri::HTML(open(url))
		var = row = 0
		@temperature = Array.new
		@humidity = Array.new
		@precipitation = Array.new
		@wind = Array.new
		doc.css("td").each_with_index do |stat, index|
			if stat.children.size == 1
				text = stat.text
			elsif stat.children.size == 2
				text = stat.children[-1].text
			elsif stat.children.size == 3
				text = stat.last_element_child.text
			else
				text = stat.text
			end
			if index == 40 || index == 73
				var = 0
				next
			end
			case var%8
			when 0
				row(row, text)
			when 1
				row(row, text)
			when 2
				row(row, text)
				row += 1
			end
			var += 1
		end

		if home_team.id == 4
			@temperature[0] = convert_to_fahr(@temperature[0])
			@temperature[1] = convert_to_fahr(@temperature[1])
			@temperature[2] = convert_to_fahr(@temperature[2])
		end
		self.update_attributes(:temperature_1 => @temperature[0], :temperature_2 => @temperature[1], :temperature_3 => @temperature[2])
		self.update_attributes(:humidity_1 => @humidity[0], :humidity_2 => @humidity[1], :humidity_3 => @humidity[2])
		self.update_attributes(:precipitation_1 => @precipitation[0], :precipitation_2 => @precipitation[1], :precipitation_3 => @precipitation[2])
		self.update_attributes(:wind_1 => @wind[0], :wind_2 => @wind[1], :wind_3 => @wind[2])
	end

	def update_weather
		
		home_team = self.home_team
		game_time = self.time
		unless game_time.include?(":")
			return
		end

		# Store all the values of time for the three hours
		game_hour_1, game_period_1 = parse_time_string_get_hour_period(game_time)
		game_hour_2, game_period_2 = next_hour(game_hour_1, game_period_1)
		game_hour_3, game_period_3 = next_hour(game_hour_2, game_period_2)

		url = @@wunderground_urls[home_team.id-1]
		puts url

		doc = nil
		begin
			Timeout::timeout(3){
				doc = Nokogiri::HTML(open(url, "Accept-Encoding" => "plain"))	
			}
		rescue Timeout::Error => e
			puts "retry"
			retry
		end
		
		elements = doc.css("#obsTable td")
		size = elements.size
		hour = amorpm = temp = humidity = pressure = dir = speed = precipitation = nil
		one = two = three = false
		# Iterate through all the rows and find the correct time and update the weather
		elements.each_with_index do |stat, index|
			case index%size
			when 0
				time = stat.text.strip
				hour, period = parse_time_string_get_hour_period(time)
				if hour == game_hour_1 && game_period_1 == period
					one = true
				elsif hour == game_hour_2 && game_period_2 == period
					two = true
				elsif hour == game_hour_3 && game_period_3 == period
					three = true
				end
			when 1
				temp = stat.text.strip
			when size - 9
				humidity = stat.text.strip
			when size - 8
				pressure = stat.text.strip
			when size - 6
				dir = stat.text.strip
			when size - 5
				speed = stat.text.strip
			when size - 3
				precipitation = stat.text.strip
				if one
					self.update_attributes(:wind_1_value => speed + " " + dir, :humidity_1_value => humidity, :pressure_1_value => pressure, :temperature_1_value => temp, :precipitation_1_value => precipitation)
				elsif two
					self.update_attributes(:wind_2_value => speed + " " + dir, :humidity_2_value => humidity, :pressure_2_value => pressure, :temperature_2_value => temp, :precipitation_2_value => precipitation)
				elsif three
					self.update_attributes(:wind_3_value => speed + " " + dir, :humidity_3_value => humidity, :pressure_3_value => pressure, :temperature_3_value => temp, :precipitation_3_value => precipitation)
				end
				one = two = three = false
			end
		end
	end

	private

		def parse_time_string_get_hour_period(time_string)
			return time_string[0...time_string.index(":")], time_string[-2..-1]
		end

		def next_hour(hour, period)

			if hour.to_i == 11
			  if period == "AM"
			    period = "PM"
			  else
			    period = "AM"
			  end
			end

			if hour.to_i == 12
				hour = "1"
			else
				hour = (hour.to_i + 1).to_s
			end

			return hour, period
		end

		@@yahoo_urls = ["https://weather.yahoo.com/united-states/california/anaheim-2354447/", "https://weather.yahoo.com/united-states/texas/houston-2424766/", "https://weather.yahoo.com/united-states/california/oakland-2463583/",
				"https://weather.yahoo.com/canada/ontario/toronto-4118/", "https://weather.yahoo.com/united-states/georgia/atlanta-2357024/", "https://weather.yahoo.com/united-states/wisconsin/milwaukee-2451822/",
				"https://weather.yahoo.com/united-states/missouri/st.-louis-2486982/", "https://weather.yahoo.com/united-states/illinois/chicago-2379574/", "https://weather.yahoo.com/united-states/arizona/phoenix-2471390/",
				"https://weather.yahoo.com/united-states/california/los-angeles-2442047/", "https://weather.yahoo.com/united-states/california/san-francisco-2487956/", "https://weather.yahoo.com/united-states/ohio/cleveland-2381475/",
				"https://weather.yahoo.com/united-states/washington/seattle-2490383/", "https://weather.yahoo.com/united-states/florida/miami-2450022/", "https://weather.yahoo.com/united-states/new-york/new-york-2459115/",
				"https://weather.yahoo.com/united-states/district-of-columbia/washington-2514815/", "https://weather.yahoo.com/united-states/maryland/baltimore-2358820/", "https://weather.yahoo.com/united-states/california/san-diego-2487889/",
				"https://weather.yahoo.com/united-states/pennsylvania/philadelphia-2471217/", "https://weather.yahoo.com/united-states/pennsylvania/pittsburgh-2473224/", "https://weather.yahoo.com/united-states/texas/arlington-2355944/",
				"https://weather.yahoo.com/united-states/florida/st.-petersburg-2487180/", "https://weather.yahoo.com/united-states/massachusetts/boston-2367105/", "https://weather.yahoo.com/united-states/ohio/cincinnati-2380358/",
				"https://weather.yahoo.com/united-states/colorado/denver-2391279/", "https://weather.yahoo.com/united-states/kansas/kansas-city-2430632/", "https://weather.yahoo.com/united-states/michigan/detroit-2391585/",
				"https://weather.yahoo.com/united-states/minnesota/minneapolis-2452078/", "https://weather.yahoo.com/united-states/illinois/chicago-2379574/", "https://weather.yahoo.com/united-states/new-york/bronx-91801630/"]

		@@accuweather_urls = ["http://www.accuweather.com/en/us/anaheim-ca/92805/hourly-weather-forecast/327150", "http://www.accuweather.com/en/us/houston-tx/77002/hourly-weather-forecast/351197", "http://www.accuweather.com/en/us/oakland-ca/94612/hourly-weather-forecast/347626",
				"http://www.accuweather.com/en/ca/toronto/m5g/hourly-weather-forecast/55488", "http://www.accuweather.com/en/us/atlanta-ga/30303/hourly-weather-forecast/348181", "http://www.accuweather.com/en/us/milwaukee-wi/53202/hourly-weather-forecast/351543",
				"http://www.accuweather.com/en/us/st-louis-mo/63101/hourly-weather-forecast/349084", "http://www.accuweather.com/en/us/chicago-il/60608/hourly-weather-forecast/348308", "http://www.accuweather.com/en/us/phoenix-az/85004/hourly-weather-forecast/346935",
				"http://www.accuweather.com/en/us/los-angeles-ca/90012/hourly-weather-forecast/347625", "http://www.accuweather.com/en/us/san-francisco-ca/94103/hourly-weather-forecast/347629", "http://www.accuweather.com/en/us/cleveland-oh/44113/hourly-weather-forecast/350127",
				"http://www.accuweather.com/en/us/seattle-wa/98104/hourly-weather-forecast/351409", "http://www.accuweather.com/en/us/miami-fl/33128/hourly-weather-forecast/347936", "http://www.accuweather.com/en/us/queens-borough-ny/11414/hourly-weather-forecast/2623321",
				"http://www.accuweather.com/en/us/washington-dc/20006/hourly-weather-forecast/327659", "http://www.accuweather.com/en/us/baltimore-md/21202/hourly-weather-forecast/348707", "http://www.accuweather.com/en/us/san-diego-ca/92101/hourly-weather-forecast/347628",
				"http://www.accuweather.com/en/us/philadelphia-pa/19107/hourly-weather-forecast/350540", "http://www.accuweather.com/en/us/pittsburgh-pa/15219/hourly-weather-forecast/1310", "http://www.accuweather.com/en/us/arlington-tx/76010/hourly-weather-forecast/331134",
				"http://www.accuweather.com/en/us/st-petersburg-fl/33712/hourly-weather-forecast/332287", "http://www.accuweather.com/en/us/boston-ma/02108/hourly-weather-forecast/348735", "http://www.accuweather.com/en/us/cincinnati-oh/45229/hourly-weather-forecast/350126",
				"http://www.accuweather.com/en/us/denver-co/80203/hourly-weather-forecast/347810", "http://www.accuweather.com/en/us/kansas-city-mo/64106/hourly-weather-forecast/329441", "http://www.accuweather.com/en/us/detroit-mi/48226/hourly-weather-forecast/348755",
				"http://www.accuweather.com/en/us/minneapolis-mn/55415/hourly-weather-forecast/348794", "http://www.accuweather.com/en/us/chicago-il/60608/hourly-weather-forecast/348308", "http://www.accuweather.com/en/us/bronx-borough-ny/10461/hourly-weather-forecast/334650"]

		@@wunderground_urls = ["https://www.wunderground.com/history/airport/KFUL/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Anaheim&req_state=CA&req_statename=California&reqdb.zip=92801&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KHOU/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Houston&req_statename=Texas", "https://www.wunderground.com/history/airport/KOAK/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Oakland&req_statename=California",
				"https://www.wunderground.com/history/airport/CYTZ/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Toronto&req_statename=Ontario", "https://www.wunderground.com/history/airport/KPDK/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Atlanta&req_statename=Georgia", "https://www.wunderground.com/history/airport/KMKE/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Milwaukee&req_statename=Wisconsin",
				"https://www.wunderground.com/history/airport/KSTL/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Saint%20Louis&req_statename=Missouri", "https://www.wunderground.com/history/airport/KMDW/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Chicago&req_state=IL&req_statename=Illinois&reqdb.zip=60290&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KPHX/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Phoenix&req_statename=Arizona",
				"https://www.wunderground.com/history/airport/KCQT/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Los%20Angeles&req_statename=California", "https://www.wunderground.com/history/airport/KSFO/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=San%20Francisco&req_statename=California", "https://www.wunderground.com/history/airport/KBKL/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Cleveland&req_statename=Ohio",
				"https://www.wunderground.com/history/airport/KBFI/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Seattle&req_state=WA&req_statename=Washington&reqdb.zip=98101&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KMIA/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Miami&req_statename=Florida", "https://www.wunderground.com/history/airport/KJFK/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Queens&req_state=NY&req_statename=New+York&reqdb.zip=11427&reqdb.magic=4&reqdb.wmo=99999",
				"https://www.wunderground.com/history/airport/KDCA/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Washington&req_state=DC&req_statename=District+of+Columbia&reqdb.zip=20001&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KBWI/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Baltimore&req_state=MD&req_statename=Maryland&reqdb.zip=21201&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KSAN/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=San%20Diego&req_statename=California",
				"https://www.wunderground.com/history/airport/KPNE/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Philadelphia&req_state=PA&req_statename=Pennsylvania&reqdb.zip=19019&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KAGC/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Pittsburgh&req_state=PA&req_statename=Pennsylvania&reqdb.zip=15122&reqdb.magic=2&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KGKY/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Arlington&req_statename=Texas",
				"https://www.wunderground.com/history/airport/KSPG/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Saint+Petersburg&req_state=FL&req_statename=Florida&reqdb.zip=33701&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KBOS/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Boston&req_state=MA&req_statename=Massachusetts&reqdb.zip=02101&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KLUK/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Cincinnati&req_state=OH&req_statename=Ohio&reqdb.zip=45201&reqdb.magic=1&reqdb.wmo=99999",
				"https://www.wunderground.com/history/airport/KAPA/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Denver&req_statename=Colorado", "https://www.wunderground.com/history/airport/KMKC/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Kansas+City&req_state=MO&req_statename=Missouri&reqdb.zip=64106&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KDET/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Detroit&req_state=MI&req_statename=Michigan&reqdb.zip=48201&reqdb.magic=1&reqdb.wmo=99999",
				"https://www.wunderground.com/history/airport/KMIC/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Minneapolis&req_state=MN&req_statename=Minnesota&reqdb.zip=55401&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KMDW/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Chicago&req_state=IL&req_statename=Illinois&reqdb.zip=60290&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KHPN/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}/DailyHistory.html?req_city=Bronxville&req_state=NY&req_statename=New+York&reqdb.zip=10708&reqdb.magic=1&reqdb.wmo=99999"]









end