module NewShare

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
    begin
      Timeout::timeout(3){
  	    doc = Nokogiri::HTML(open(url, allow_redirections: :all))
  	  }
    rescue OpenURI::HTTPError, Errno::ECONNREFUSED, Errno::ECONNRESET, Timeout::Error, URI::InvalidURIError, Zlib::BufError => e
      retry
    end
    return doc
  end

  def find_date(time)
    return time.hour, time.day, time.month, time.year
  end

  def is_preseason?(time)
    hour, day, month, year = find_date(time)
    if month.to_i < 4 || (month.to_i == 4 && day.to_i < 3)
  	  true
  	else
  	  false
  	end
  end

  def pitcher_info(element)
    name = element.child.text
    identity = element.child['data-bref']
	  fangraph_id = element.child['data-razz'].gsub!(/[^0-9]/, "")
	  handedness = element.children[1].text[2]
	  return identity, fangraph_id, name, handedness
  end

  def batter_info(element)
	  name = element.children[1].text
	  lineup = element.child.to_s[0].to_i
	  handedness = element.children[2].to_s[2]
	  position = element.children[2].to_s.match(/\w*$/).to_s
	  identity = element.children[1]['data-bref']
	  fangraph_id = element.children[1]['data-razz'].gsub!(/[^0-9]/, "")
	  return identity, fangraph_id, name, handedness, lineup, position
  end

end