module Share

  require 'open-uri'
  require 'open_uri_redirections'
  require 'nokogiri'
  require 'mechanize'
  require 'timeout'

  def mechanize_page(url)
    page = nil
    begin
      Timeout::timeout(3){
        page = Mechanize.new.get(url)
      }
    rescue Errno::ECONNREFUSED, Timeout::Error, URI::InvalidURIError => e
      retry
    end
    return page
  end
  
  def download_document(url)
  	doc = nil
    count = 0
    begin
      Timeout::timeout(3){
  	    doc = Nokogiri::HTML(open(url, allow_redirections: :all))
  	  }
    rescue Errno::ECONNREFUSED, Timeout::Error, URI::InvalidURIError, Zlib::BufError => e
      count += 1
      if count < 3
        retry
      else
        next
      end
    end
    return doc
  end

  def num_find_date(time)
    return time.hour, time.day, time.month, time.year
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

  def new_find_player(name, identity)
    player = nil
    if identity && identity != ""
      player = Player.find_by_identity(identity)
    end
    unless player
      player = Player.find_by_name(name)
    end
    return player
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