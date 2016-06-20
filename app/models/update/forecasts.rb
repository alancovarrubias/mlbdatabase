module Update
  class Forecasts

    include NewShare

    def update(game)
      create_weather(game)
      update_pressure(game)
      update_forecast(game)
    end

    private
      def create_weather(game)
        if game.weathers.where(station: "Forecast").size == 0
          (1..3).each do |i|
            Weather.create(game: game, station: "Forecast", hour: i)
          end
        end          
      end

      def update_pressure(game)
        game_day = game.game_day
    	  home_team = game.home_team
    	  url = "https://www.wunderground.com/cgi-bin/findweather/getForecast?query=#{home_team.zipcode}"
  	  	page = mechanize_page(url)

        page.search("#current td").each_with_index do |stat, index|
  	    	if index == 1
  	      	pressure = stat.text.strip[0..4] + ' in'
            game.weathers.where(station: "Forecast").update_all(pressure: pressure)
            break
  	    	end
        end
      end

      def update_forecast(game)

        game_day = game.game_day
    	  game_time = game.time
    	  unless game_time.include?(":")
    	    return
    	  end
    	  game_hour = game_time[0...game_time.index(":")].to_i
    	  period = game_time[-2..-1]
    	  game_hour = convert_to_military_hour(game_hour, period)
        if game_day == GameDay.search(Time.now)
    	  elsif game_day == GameDay.search(Time.now.tomorrow)
    	    game_hour += 24
        else
          return
        end

        home_team = game.home_team
    	  url = @@urls[home_team.id-1]
        url += "?hour=#{game_hour}"
        doc = download_document(url)
        return unless doc
        puts url
        initialize_arrays
        var = row = 0
        doc.css("td").each_with_index do |stat, index|
          text = get_accuweather_text(stat)
          if index == 40 || index == 73
            var = 0
            next
          end
          case var%8
          when 0
            add_to_array(row, text)
          when 1
            add_to_array(row, text)
          when 2
            add_to_array(row, text)
            row += 1
          end
          var += 1
        end

        if home_team.id == 4
  		    (0..2).each do |i|
  		      @temp[i] = convert_to_fahr(@temp[i])
  		    end
        end

        game.weathers.where(station: "Forecast").order("hour").each_with_index do |weather, index|
      		weather.update(temp: @temp[index], humidity: @humidity[index], rain: @rain[index], wind: @wind[index], feel: @feel[index], dew: @dew[index])
        end
      end

      def initialize_arrays
        @temp = Array.new
        @humidity = Array.new
        @rain = Array.new
        @wind = Array.new
        @feel = Array.new
        @dew = Array.new
      end

	    def convert_to_fahr(celsius)
	      symbol = celsius[-1]
	      celsius = celsius[0...-1].to_f
	      fahr = (celsius * 9.0 / 5.0 + 32.0).round.to_s
	      fahr += symbol
	      fahr
	    end

	    def add_to_array(row, text)
	      case row
	      when 2
	        @temp << text
	      when 3
	        @feel << text
	      when 4
	        @humidity << text
	      when 6
	        @rain << text
	      when 10
	        @wind << text
	      when 13
	        @dew << text
	      end 
	    end

	    def get_accuweather_text(element)
	      if element.children.size == 2
	        element.children[-1].text
	      elsif element.children.size == 3
	        element.last_element_child.text
	      else
	        element.text
	      end
	    end

	    def convert_to_military_hour(hour, period)
	  	  if period == "PM" && hour != 12
	        hour += 12
	      end
	      hour
	    end



    @@urls = ["http://www.accuweather.com/en/us/anaheim-ca/92805/hourly-weather-forecast/327150", "http://www.accuweather.com/en/us/houston-tx/77002/hourly-weather-forecast/351197", "http://www.accuweather.com/en/us/oakland-ca/94612/hourly-weather-forecast/347626",
    "http://www.accuweather.com/en/ca/toronto/m5g/hourly-weather-forecast/55488", "http://www.accuweather.com/en/us/atlanta-ga/30303/hourly-weather-forecast/348181", "http://www.accuweather.com/en/us/milwaukee-wi/53202/hourly-weather-forecast/351543",
    "http://www.accuweather.com/en/us/st-louis-mo/63101/hourly-weather-forecast/349084", "http://www.accuweather.com/en/us/chicago-il/60608/hourly-weather-forecast/348308", "http://www.accuweather.com/en/us/phoenix-az/85004/hourly-weather-forecast/346935",
    "http://www.accuweather.com/en/us/los-angeles-ca/90012/hourly-weather-forecast/347625", "http://www.accuweather.com/en/us/san-francisco-ca/94103/hourly-weather-forecast/347629", "http://www.accuweather.com/en/us/cleveland-oh/44113/hourly-weather-forecast/350127",
    "http://www.accuweather.com/en/us/seattle-wa/98104/hourly-weather-forecast/351409", "http://www.accuweather.com/en/us/miami-fl/33128/hourly-weather-forecast/347936", "http://www.accuweather.com/en/us/queens-borough-ny/11414/hourly-weather-forecast/2623321",
    "http://www.accuweather.com/en/us/washington-dc/20006/hourly-weather-forecast/327659", "http://www.accuweather.com/en/us/baltimore-md/21202/hourly-weather-forecast/348707", "http://www.accuweather.com/en/us/san-diego-ca/92101/hourly-weather-forecast/347628",
    "http://www.accuweather.com/en/us/philadelphia-pa/19107/hourly-weather-forecast/350540", "http://www.accuweather.com/en/us/pittsburgh-pa/15219/hourly-weather-forecast/1310", "http://www.accuweather.com/en/us/arlington-tx/76010/hourly-weather-forecast/331134",
    "http://www.accuweather.com/en/us/st-petersburg-fl/33712/hourly-weather-forecast/332287", "http://www.accuweather.com/en/us/boston-ma/02108/hourly-weather-forecast/348735", "http://www.accuweather.com/en/us/cincinnati-oh/45229/hourly-weather-forecast/350126",
    "http://www.accuweather.com/en/us/denver-co/80203/hourly-weather-forecast/347810", "http://www.accuweather.com/en/us/kansas-city-mo/64106/hourly-weather-forecast/329441", "http://www.accuweather.com/en/us/detroit-mi/48226/hourly-weather-forecast/348755",
    "http://www.accuweather.com/en/us/minneapolis-mn/55415/hourly-weather-forecast/348794", "http://www.accuweather.com/en/us/chicago-il/60608/hourly-weather-forecast/348308", "http://www.accuweather.com/en/us/bronx-borough-ny/10461/hourly-weather-forecast/334650"]



  end
end