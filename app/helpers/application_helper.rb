module ApplicationHelper
  require 'date'

  def num_batters_with_handedness(lancer, batters)
    # Make switch hitters count as different to pitcher's handedness
    throwhand = lancer.player.throwhand
  	same = batters.select { |batter| batter.player.bathand == throwhand }.size
  	diff = batters.size - same

    if throwhand == "L"
      return same, diff
    else
      return diff, same
    end
  end

  def mixed_statistic(lefty_stat, righty_stat, num_lefty, num_righty)
    if num_lefty + num_righty == 0
      lefty_stat
    else
      ((lefty_stat * num_lefty + righty_stat * num_righty)/(num_lefty + num_righty)).round(2)
    end
  end

end
