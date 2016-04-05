# Shared amongst multiple modules
module Share

  require 'open-uri'
  require 'nokogiri'
  require 'timeout'
  
  def download_document(url)
  	doc = nil
    begin
      Timeout::timeout(3){
  	    doc = Nokogiri::HTML(open(url))
  	  }
    rescue Errno::ECONNREFUSED, Timeout::Error, URI::InvalidURIError => e
    end
    return doc
  end

  def find_date(today)
	  year = "%d" % today.year
	  month = "%02d" % today.month
	  day = "%02d" % today.day
	  hour = "%02d" % today.hour
	  return hour, day, month, year
  end

  def is_preseason?(time)
    hour, day, month, year = find_date(time)
    if month.to_i < 4 || (month.to_i == 4 && day.to_i < 3)
	    true
	  else
	    false
	  end
  end

  def find_player(proto_players, identifier, fangraph_id, name)
    if identifier.size > 0 && player = proto_players.find_by_alias(identifier)
	  elsif fangraph_id && player = proto_players.find_by_fangraph_id(fangraph_id)
	  elsif player = proto_players.find_by_name(name)
	  else
	    return nil
	  end
	  return player
  end

  def pitcher_info(element)
    name = element.child.text
    identifier = element.child['data-bref']
	  fangraph_id = element.child['data-razz'].gsub!(/[^0-9]/, "")
	  handedness = element.children[1].text[2]
	  return identifier, fangraph_id, name, handedness
  end

end