module Update
  class Weathers

  	include NewShare

    def update(game)

      create_weathers(game)

      game_time = game.time
      game_day = game.game_day
      home_team = game.home_team
      local_hour = game.local_hour
      local_hour = 18 if local_hour == 0

      if game_time.include?(":")
        @game_hour_1, @game_period_1 = parse_time_string_get_hour_period(game_time)
      else
        @game_hour_1, @game_period_1 = local_hour_get_hour_period(local_hour)
      end

      @game_hour_2, @game_period_2 = next_hour(@game_hour_1, @game_period_1)
      @game_hour_3, @game_period_3 = next_hour(@game_hour_2, @game_period_2)

      url = get_url(home_team, game_day)
      page = mechanize_page(url)
      puts url

      return unless page
      size = page.search("#obsTable th").size
      return if size == 0
      index_hash = {temp: 1, dew: 2, humidity: 3, pressure: 4, wind_dir: 6, wind_speed: 7, precip: 9}
      update_index_hash(index_hash, size)
      elements = page.search("#obsTable td")
      weathers = game.weathers.where(station: "Actual")
      elements.each_slice(size) do |slice|
        weather = get_weather(slice[0], weathers)
        next unless weather
        temp = slice[index_hash[:temp]].text.strip
        dew = slice[index_hash[:dew]].text.strip
        humidity = slice[index_hash[:humidity]].text.strip
        pressure = slice[index_hash[:pressure]].text.strip
        dir = slice[index_hash[:wind_dir]].text.strip
        speed = slice[index_hash[:wind_speed]].text.strip
        rain = slice[index_hash[:precip]].text.strip
        weather.update(wind: speed + " " + dir, speed: speed, dir: dir, dew: dew, humidity: humidity, pressure: pressure, temp: temp, rain: rain)
        weather.update(air_density: weather.air_density)
      end

      weather = game.true_weather
      if weather
        game.update(temp: weather.temp_num, dew: weather.dew_num, baro: weather.baro_num, humid: weather.humid_num)
      end

    end

    private

      def update_index_hash(index_hash, size)
        if size == 13
          index_hash.each do |k, v|
            index_hash[k] += 1 unless k == :temp
          end
        end
      end

      def get_weather(element, weathers)
        time = element.text.strip
        hour, period = parse_time_string_get_hour_period(time)
        if hour == @game_hour_1 && @game_period_1 == period
          weathers.find_by(hour: 1)
        elsif hour == @game_hour_2 && @game_period_2 == period
          weathers.find_by(hour: 2)
        elsif hour == @game_hour_3 && @game_period_3 == period
          weathers.find_by(hour: 3)
        else
          nil
        end
      end

      def get_url(home_team, game_day)
        url = @@urls[home_team.id-1]
        find = "year/month/day"
        replace = "#{game_day.year}/#{game_day.month}/#{game_day.day}"
        url.gsub(/#{find}/, replace)
      end

      def parse_time_string_get_hour_period(time_string)
        index = time_string.index(":")
        hour = time_string[0...index].to_i
        period = time_string[-2..-1]
        return hour, period
      end

      def local_hour_get_hour_period(local_hour)
        if local_hour == 0
          hour = 7
          period = "PM"
        else
          period = local_hour < 13 ? "AM" : "PM"
          hour = local_hour > 12 ? local_hour - 12 : local_hour
        end
        return hour, period
      end

      def next_hour(hour, period)
        if hour == 11
          if period == "AM"
            period = "PM"
          else
            period = "AM"
          end
        end

        if hour == 12
          hour = 1
        else
          hour = hour + 1
        end

        return hour, period
      end

      def create_weathers(game)
        if game.weathers.where(station: "Actual").size == 0
          (1..3).each do |i|
            Weather.create(game: game, station: "Actual", hour: i)
          end
        end
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
    	"https://www.wunderground.com/history/airport/KMIC/year/month/day/DailyHistory.html?req_city=Minneapolis&req_state=MN&req_statename=Minnesota&reqdb.zip=55401&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KMDW/year/month/day/DailyHistory.html?req_city=Chicago&req_state=IL&req_statename=Illinois&reqdb.zip=60290&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/KHPN/year/month/day/DailyHistory.html?req_city=Bronxville&req_state=NY&req_statename=New+York&reqdb.zip=10708&reqdb.magic=1&reqdb.wmo=99999",
      "https://www.wunderground.com/history/airport/KMIA/year/month/day/DailyHistory.html?req_city=Miami&req_statename=Florida", "https://www.wunderground.com/history/airport/KSPG/year/month/day/DailyHistory.html?req_city=Saint+Petersburg&req_state=FL&req_statename=Florida&reqdb.zip=33701&reqdb.magic=1&reqdb.wmo=99999", "https://www.wunderground.com/history/airport/CYHU/year/month/day/DailyHistory.html?req_city=Montreal%20/%20St-Hubert&req_statename=Quebec&reqdb.zip=00000&reqdb.magic=9&reqdb.wmo=71371", "https://www.wunderground.com/history/airport/KFUL/year/month/day/DailyHistory.html?req_city=Anaheim&req_state=CA&req_statename=California&reqdb.zip=92801&reqdb.magic=1&reqdb.wmo=99999"]

  end
end
