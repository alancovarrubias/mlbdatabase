module Update
  class WeatherSource

    def update(game)
      home_team = game.home_team
      if home_team.name == "Blue Jays"
        return
      end
      offset = -5 + home_team.timezone
      date = game.game_day.date
      date_string = "%d-%02d-%02dT%02d:00:00%03d:00" % [date.year, date.month, date.day, game.local_hour, offset]
      url = "https://api.weathersource.com/v1/bd511e5eeb837ddb1c4e/history_by_postal_code.json?period=hour&postal_code_eq=#{home_team.zipcode}&country_eq=US&timestamp_eq=#{date_string}&fields=postal_code,country,timestamp,temp,precipConf,windSpd,dewPt,feelsLike,relHum,sfcPres"
      response = RestClient.get(url)
      puts JSON.parse(response)
    end

  end
end