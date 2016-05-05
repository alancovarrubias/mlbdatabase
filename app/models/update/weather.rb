module Update
  class Weather

  	include NewShare

  	def initialize(game)
  	  @game = game
  	end

  	  # Data scraped from wunderground
    def update
    
      game_time = @game.time
      unless game_time.include?(":")
        return
      end

      game_day = @game.game_day
      home_team = @game.home_team

      game_hour_1, game_period_1 = parse_time_string_get_hour_period(game_time)
      game_hour_2, game_period_2 = next_hour(game_hour_1, game_period_1)
      game_hour_3, game_period_3 = next_hour(game_hour_2, game_period_2)

      url = @@urls[home_team.id-1]
      find = "year/month/day"
      replace = "#{game_day.year}/#{game_day.month}/#{game_day.day}"
      url = url.gsub(/#{find}/, replace)

      page = mechanize_page(url)

      puts url
    
      size = page.search("#obsTable th").size
      elements = page.search("#obsTable td")
      temp = humidity = pressure = rain = dir = speed  = dew = nil
      weathers = @game.weathers.where(station: "Actual")
      weather = nil
      elements.each_with_index do |stat, index|
        case index%size
        when 0
          time = stat.text.strip
          hour, period = parse_time_string_get_hour_period(time)
          if hour == game_hour_1 && game_period_1 == period
            weather = weathers.find_by(hour: 1)
          elsif hour == game_hour_2 && game_period_2 == period
            weather = weathers.find_by(hour: 2)
          elsif hour == game_hour_3 && game_period_3 == period
            weather = weathers.find_by(hour: 3)
          else
            weather = nil
          end
        when 1
          temp = stat.text.strip
        when 2
          dew = stat.text.strip
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
            weather.update_attributes(wind: speed + " " + dir, speed: speed, dir: dir, dew: dew, humidity: humidity, pressure: pressure, temp: temp, rain: rain)
          end
        end
      end
    end

    private

    def get_url
      url = @@urls[home_team.id-1]
      find = "year/month/day"
      replace = "#{game_day.year}/#{game_day.month}/#{game_day.day}"
      url.gsub(/#{find}/, replace)
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


  	@@urls = ["https://www.wunderground.com/history/airport/KFUL/year/month/day/DailyHistory.html?req_city=Anaheim&req_state=CA&req_statename=California&reqdb.zip=92801&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KHOU/year/month/day/DailyHistory.html?req_city=Houston&req_statename=Texas", "https://www.wunderground.com/history/airport/KOAK/year/month/day/DailyHistory.html?req_city=Oakland&req_statename=California",
  	"https://www.wunderground.com/history/airport/CYTZ/year/month/day/DailyHistory.html?req_city=Toronto&req_statename=Ontario", "https://www.wunderground.com/history/airport/KPDK/year/month/day/DailyHistory.html?req_city=Atlanta&req_statename=Georgia", "https://www.wunderground.com/history/airport/KMKE/year/month/day/DailyHistory.html?req_city=Milwaukee&req_statename=Wisconsin",
  	"https://www.wunderground.com/history/airport/KSTL/year/month/day/DailyHistory.html?req_city=Saint%20Louis&req_statename=Missouri", "https://www.wunderground.com/history/airport/KMDW/year/month/day/DailyHistory.html?req_city=Chicago&req_state=IL&req_statename=Illinois&reqdb.zip=60290&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KPHX/year/month/day/DailyHistory.html?req_city=Phoenix&req_statename=Arizona",
  	"https://www.wunderground.com/history/airport/KCQT/year/month/day/DailyHistory.html?req_city=Los%20Angeles&req_statename=California", "https://www.wunderground.com/history/airport/KSFO/year/month/day/DailyHistory.html?req_city=San%20Francisco&req_statename=California", "https://www.wunderground.com/history/airport/KBKL/year/month/day/DailyHistory.html?req_city=Cleveland&req_statename=Ohio",
  	"https://www.wunderground.com/history/airport/KBFI/year/month/day/DailyHistory.html?req_city=Seattle&req_state=WA&req_statename=Washington&reqdb.zip=98101&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KMIA/year/month/day/DailyHistory.html?req_city=Miami&req_statename=Florida", "https://www.wunderground.com/history/airport/KJFK/year/month/day/DailyHistory.html?req_city=Queens&req_state=NY&req_statename=New+York&reqdb.zip=11427&reqdb.magic=4&reqdb.wmo=99999",
  	"https://www.wunderground.com/history/airport/KDCA/year/month/day/DailyHistory.html?req_city=Washington&req_state=DC&req_statename=District+of+Columbia&reqdb.zip=20001&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KBWI/year/month/day/DailyHistory.html?req_city=Baltimore&req_state=MD&req_statename=Maryland&reqdb.zip=21201&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KSAN/year/month/day/DailyHistory.html?req_city=San%20Diego&req_statename=California",
  	"https://www.wunderground.com/history/airport/KPNE/year/month/day/DailyHistory.html?req_city=Philadelphia&req_state=PA&req_statename=Pennsylvania&reqdb.zip=19019&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KAGC/year/month/day/DailyHistory.html?req_city=Pittsburgh&req_state=PA&req_statename=Pennsylvania&reqdb.zip=15122&reqdb.magic=2&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KGKY/year/month/day/DailyHistory.html?req_city=Arlington&req_statename=Texas",
  	"https://www.wunderground.com/history/airport/KSPG/year/month/day/DailyHistory.html?req_city=Saint+Petersburg&req_state=FL&req_statename=Florida&reqdb.zip=33701&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KBOS/year/month/day/DailyHistory.html?req_city=Boston&req_state=MA&req_statename=Massachusetts&reqdb.zip=02101&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KLUK/year/month/day/DailyHistory.html?req_city=Cincinnati&req_state=OH&req_statename=Ohio&reqdb.zip=45201&reqdb.magic=1&reqdb.wmo=99999",
  	"https://www.wunderground.com/history/airport/KAPA/year/month/day/DailyHistory.html?req_city=Denver&req_statename=Colorado", "https://www.wunderground.com/history/airport/KMKC/year/month/day/DailyHistory.html?req_city=Kansas+City&req_state=MO&req_statename=Missouri&reqdb.zip=64106&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KDET/year/month/day/DailyHistory.html?req_city=Detroit&req_state=MI&req_statename=Michigan&reqdb.zip=48201&reqdb.magic=1&reqdb.wmo=99999",
  	"https://www.wunderground.com/history/airport/KMIC/year/month/day/DailyHistory.html?req_city=Minneapolis&req_state=MN&req_statename=Minnesota&reqdb.zip=55401&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KMDW/year/month/day/DailyHistory.html?req_city=Chicago&req_state=IL&req_statename=Illinois&reqdb.zip=60290&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KHPN/year/month/day/DailyHistory.html?req_city=Bronxville&req_state=NY&req_statename=New+York&reqdb.zip=10708&reqdb.magic=1&reqdb.wmo=99999"]

  end
end