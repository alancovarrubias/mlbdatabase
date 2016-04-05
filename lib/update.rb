module Update

  require 'nokogiri'
  require 'open-uri'
  require 'timeout'

  def update_pitchers_ops(team, year)
  	Pitcher.where(game_id: nil, team_id: team.id).each do |pitcher|
  	  if pitcher.alias == nil || pitcher.alias == ""
  	  	next
  	  end
  	  url = "http://www.baseball-reference.com/players/split.cgi?id=#{pitcher.alias}&year=#{year}&t=p"
  	  puts url
	    doc = nil
	    begin
	      Timeout::timeout(3){
	  	    doc = Nokogiri::HTML(open(url))
	  	  }
	    rescue Errno::ECONNREFUSED, Timeout::Error, URI::InvalidURIError => e
	  	  next
	    end
  	  row = 0
  	  doc.css("#plato td").each_with_index do |element, index|
  	  	case index%28
  	  	when 27
  	  	  ops = element.text.to_i
  	  	  case row
  	  	  when 0
  	  	  	if year == 2015
  	  	  	  pitcher.update_attributes(OPS_R: ops)
  	  	  	elsif year == 2014
  	  	  	  pitcher.update_attributes(OPS_previous_R: ops)
  	  	  	end
  	  	  when 1
  	  	  	if year == 2015
  	  	  	  pitcher.update_attributes(OPS_L: ops)
  	  	  	elsif year == 2014
  	  	  	  pitcher.update_attributes(OPS_previous_L: ops)
  	  	  	end
  	  	  end
  	  	  row += 1
  	  	end
  	  	if row == 2
  	  	  break
  	  	end
  	  end
  	end
  end

end