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


  def get_batter_stats(batter, left)
    stat_array = Array.new
    handed = get_handed(left)
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

  def get_handed(left)
    if left
      "L"
    else
      "R"
    end
  end

  def get_lancer_stats(lancer)
    stat_array = Array.new
    stat_array << lancer.stats
    player = lancer.player
    season = Season.find_by_year(lancer.season.year-1)
    while season
      lancer = player.create_lancer(season)
      stat_array << lancer.stats
      season = Season.find_by_year(season.year-1)
    end
    return stat_array
  end


  def get_lefty_righty(index)
    if index == 0
      return @home_lefties, @home_righties
    else
      return @away_lefties, @away_righties
    end
  end

  def mixed_stat(lefty_stat, righty_stat, lefties, righties)
    ((lefty_stat * lefties + righty_stat * righties)/9).round(2)
  end

  def bullpen_day_name(num)
    require 'date'
    num += 1
    day = Date.parse("#{@game_day.year}-#{@game_day.month}-#{@game_day.day}").wday
    return Date::DAYNAMES[day-num]
  end


  def handed_hitter_header(hand)
    if hand
      "LHP"
    else
      "RHP"
    end
  end

end
