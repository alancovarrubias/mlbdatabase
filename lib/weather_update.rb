module WeatherUpdate

  include NewShare

  def create_weathers(game)
    if game.weathers.size == 0
      (1..3).each do |i|
        Weather.create(game_id: game.id, station: "Forecast", hour: i)
        Weather.create(game_id: game.id, station: "Actual", hour: i)
      end
    end
  end

  # Data scraped from Wunderground
  def update_pressure_forecast(game)
  	home_team = game.home_team
  	url = "https://www.wunderground.com/cgi-bin/findweather/getForecast?query=#{home_team.zipcode}"
	  page = mechanize_page(url)

    page.search("#current td").each_with_index do |stat, index|
	  if index == 1
	    pressure = stat.text.strip[0..4] + ' in'
        game.weathers.where(station: "Forecast").each do |weather|
          weather.update_attributes(pressure: pressure)
        end
        break
	  end
    end
  end

  # Data scraped from Accuweather
  def update_forecast(game, time)

  	# Game time must include a colon
  	game_time = game.time
  	unless game_time.include?(":")
  	  return
  	end

  	game_hour = game_time[0..game_time.index(":")].to_i
  	period = game_time[-2..-1]

  	game_hour = convert_to_military_hour(game_hour, period)

  	if time.day == Time.now.tomorrow.day
  	  game_hour += 24
    end

    home_team = game.home_team
  	url = @@accuweather_urls[home_team.id-1]
    url += "?hour=#{game_hour}"
    doc = download_document(url)
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
      puts @feel[index]
    	weather.update(temp: @temp[index], humidity: @humidity[index], rain: @rain[index], wind: @wind[index], feel: @feel[index], dew: @dew[index])
    end
  end

  # Data scraped from wunderground
  def update_weather(game)
    
    puts game.new_url
    home_team = game.home_team
    game_time = game.time
    unless game_time.include?(":")
      return
    end

    # Store all the values of time for the three hours
    game_hour_1, game_period_1 = parse_time_string_get_hour_period(game_time)
    game_hour_2, game_period_2 = next_hour(game_hour_1, game_period_1)
    game_hour_3, game_period_3 = next_hour(game_hour_2, game_period_2)

    url = @@wunderground_urls[home_team.id-1]

    page = mechanize_page(url)
    
    size = page.search("#obsTable th").size
    elements = page.search("#obsTable td")
    temp = humidity = pressure = rain = dir = speed  = nil
    weathers = game.weathers.where(station: "Actual")
    weather = nil
    elements.each_with_index do |stat, index|
      case index%size
      when 0
        time = stat.text.strip
        hour, period = parse_time_string_get_hour_period(time)
        if hour == game_hour_1 && game_period_1 == period
          weather = weathers.where(hour: 1).first
        elsif hour == game_hour_2 && game_period_2 == period
          weather = weathers.where(hour: 2).first
        elsif hour == game_hour_3 && game_period_3 == period
          weather = weathers.where(hour: 3).first
        else
          weather = nil
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
        rain = stat.text.strip
        if weather
          weather.update_attributes(wind: speed + " " + dir, humidity: humidity, pressure: pressure, temp: temp, rain: rain)
        end
      end
    end
  end

  private

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
      return fahr
    end

    def add_to_array(row, text)
      case row
      when 2
        @temp << text
      when 3
        puts text
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
        text = element.children[-1].text
      elsif element.children.size == 3
        text = element.last_element_child.text
      else
        text = element.text
      end
      return text
    end

    def convert_to_military_hour(hour, period)
  	  if period == "PM" && hour != 12
        hour += 12
      end
      return hour
    end

    def parse_time_string_get_hour_period(time_string)
      index = time_string.index(":")
      return time_string[0...index], time_string[-2..-1]
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