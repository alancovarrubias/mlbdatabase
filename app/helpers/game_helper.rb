module GameHelper

  def batter_class(predicted)
    if predicted
      "predicted batter"
    else
      "batter"
    end
  end
  
  def weather_time(game_time, weather_hour)
  	weather_hour -= 1

  	colon_index = game_time.index(":")
  	game_hour = game_time[0...colon_index].to_i
  	game_minutes = game_time[colon_index+1..colon_index+2]
  	game_period = game_time[-2..-1]

  	weather_hour = game_hour + weather_hour
  	# Check if period needs to be changed
  	if game_hour != 12 && weather_hour >= 12
  	  if weather_hour > 12
  	  	weather_hour -= 12
  	  end
  	  if game_period == "PM"
  	  	game_period = "AM"
  	  else
  	  	game_period = "PM"
  	  end
  	end

  	weather_time = weather_hour.to_s + ":" + game_minutes + " " + game_period

  	return weather_time
  end


  def batter_stats(batter, left)
    stat_array = Array.new
    handed = handedness(left)
    stats = batter.stats
    stat_array << stats.where(handedness: handed).first
    stat_array << stats.where(handedness: "").first
    player = batter.player
    season = Season.find_by_year(batter.season.year-1)
    while season
      batter = player.create_batter(season)
      stat_array << batter.stats.where(handedness: handed).first
      season = Season.find_by_year(season.year-1)
    end
    return stat_array
  end

  def handedness(left)
    if left
      "L"
    else
      "R"
    end
  end

  def lancer_stats(pitcher)
    stat_array = Array.new
    stat_array << pitcher.stats
    player = pitcher.player
    season = Season.find_by_year(pitcher.season.year-1)
    while season
      pitcher = player.create_lancer(season)
      stat_array << pitcher.stats
      season = Season.find_by_year(season.year-1)
    end
    return stat_array
  end


  def lefty_righty(index)

    if index == 0
      return num_batters_with_handedness(@away_starting_lancer.first, @home_batters)
    else
      return num_batters_with_handedness(@home_starting_lancer.first, @away_batters)
    end

  end

  def bullpen_day_name(num)

    num += 1
    day = Date.parse("#{@game_day.year}-#{@game_day.month}-#{@game_day.day}").wday
    return Date::DAYNAMES[day-num]

  end


  def handedness_header(left)

    if left
      "LHP"
    else
      "RHP"
    end

  end

end
