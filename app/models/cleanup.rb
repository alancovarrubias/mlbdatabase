module Cleanup
  module_function
  extend NewShare
  def prev_pitchers(game_day)
    game_day.games.each do |game|
      update_pitchers(game)
    end
  end

  def update_pitchers(game)
    pitchers = game.lancers.where(starter: true)
    pitchers.each do |pitcher|
      prev_pitchers = pitcher.prev_pitchers
      update_prev_pitchers(prev_pitchers)
    end
  end

  def update_prev_pitchers(prev_pitchers)
    prev_pitchers.each do |pitcher|
      if pitcher.ip == 0
        game = pitcher.game
        game_day = game.game_day
        season = game_day.season
        name = game.home_team.name.sub(" ", "%20")
        player = pitcher.player
        fangraph_id = player.fangraph_id
        next unless season && player && game_day
        url = "http://www.fangraphs.com/livewins.aspx?date=#{game_day.date}&team=#{name}&dh=0&season=#{season.year}"
        puts url
        doc = download_document(url)
        css = "td tr:nth-child(1) .rgMasterTable .grid_line_regular"
        next unless doc
        elements = doc.css(css)
        elements.each_slice(9) do |slice|
          id_str = slice[0].child["href"]
          if id_str
            if fangraph_id == /(?<==)\d*&/.match(id_str).to_s[0...-1].to_i
              ip = slice[1].text.to_f
              h = slice[2].text.to_i
              er = slice[4].text.to_i
              bb = slice[5].text.to_i
              puts player.name
              puts ip
              pitcher.update(ip: ip, h: h, r: er, bb: bb)
            end
          end
        end
      end
    end
  end

end
