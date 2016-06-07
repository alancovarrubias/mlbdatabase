module Update
  class WeatherSources

    def update(game)
      home_team = game.home_team
      if home_team.name == "Blue Jays"
        return
      end
      offset = -5 + home_team.timezone
      date = game.game_day.date
      (0..2).each do |i|
        local_hour = game.local_hour + i
        date_string = "%d-%02d-%02dT%02d:00:00%03d:00" % [date.year, date.month, date.day, local_hour, offset]
        url = "https://api.weathersource.com/v1/bd511e5eeb837ddb1c4e/history_by_postal_code.json?period=hour&postal_code_eq=#{home_team.zipcode}&country_eq=US&timestamp_eq=#{date_string}&fields=postal_code,country,timestamp,temp,precip,windSpd,dewPt,feelsLike,relHum,sfcPres,cldCvr,spcHum"
        puts url
        response = RestClient.get(url)
        hash = JSON.parse(response).first
        unless weather_source = game.weather_sources.find_by(hour: local_hour)
          weather_source = WeatherSource.create(game: game, hour: local_hour)
        end
        puts hash
        weather_source.update(temp: hash['temp'], precip: hash['precip'], windSpd: hash['windSpd'], cldCvr: hash['cldCvr'], 
          dewPt: hash['dewPt'], feelsLike: hash['feelsLike'], relHum: hash['relHum'], sfcPres: hash['sfcPres'], spcHum: hash['spcHum'])
      end
    end

  end
end