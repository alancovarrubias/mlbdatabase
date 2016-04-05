module Bullpen

  include Share

  def find_or_create_bullpen_pitcher(element)
	identifier, fangraph_id, name, handedness = pitcher_info(element)
	pitcher = find_player(Pitcher.proto_pitchers, identifier, fangraph_id, name)
	unless pitcher
	  pitcher = Pitcher.create(name: name, alias: identifier, throwhand: handedness, fangraph_id: fangraph_id)
	end
	return pitcher
  end

  def get_pitches(text)
    if text == "N/G"
	  return 0
	else
	  return text.to_i
	end
  end

  def set_bullpen

    Pitcher.bullpen_pitchers.update_all(bullpen: false)

    url = "http://www.baseballpress.com/bullpenusage"
    doc = download_document(url)

	pitcher = nil
	var = one = two = three = 0
	doc.css(".league td").each do |element|

	  text = element.text
	  case var
	  when 1
	    one = get_pitches(text)
		var += 1
	  when 2
		two = get_pitches(text)
		var += 1
	  when 3
		three = get_pitches(text)
		pitcher.update_attributes(bullpen: true, one: one, two: two, three: three)
		var = 0
	  end

	  # Elements with two children contain the pitcher information
	  if element.children.size == 2
	  	pitcher = find_or_create_bullpen_pitcher(element)
		var = 1
	  end
	end

	url = "http://www.baseballpress.com/bullpenusage/#{DateTime.now.yesterday.yesterday.yesterday.to_date}"
	doc = download_document(url)

	pitcher = nil
	var = four = five = 0
	doc.css(".league td").each do |element|

	  text = element.text
	  case var
	  when 1
		var += 1
	  when 2
		four = get_pitches(text)
		var += 1
	  when 3
		five = get_pitches(text)
		pitcher.update_attributes(:four => four, :five => five)
		var = 0
	  end

	  if element.children.size == 2
	  	pitcher = find_or_create_bullpen_pitcher(element)
		var = 1
	  end

	end
  end

end