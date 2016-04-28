namespace :transaction do

  task test: :environment do

  	def get_name(team)
	  name = team.name.downcase.gsub(/\s+/, "")
  	  if name == "diamondbacks"
  	  	name = "dbacks"
  	  end
  	  return name
  	end

  	def month_day(name, element)
  	  text = element.text[0...-3]
  	  index = text.index("/")
  	  month = text[0...index].to_i
  	  day = text[index+1..-1].to_i
  	  if name == "bluejays"
  	  	temp = day
  	  	day = month
  	  	month = temp
  	  end
  	  return month, day
  	end

  	include NewShare
  	Team.all.each do |team|
  	  name = get_name(team)
  	  unless name == "orioles"
  	  	next
  	  end
  	  url = "http://m.#{name}.mlb.com/roster/transactions"
  	  puts url
  	  doc = download_document(url)
  	  month = day = nil
  	  doc.css("td").each_with_index do |element, index|
  	  	case index%2
  	  	when 0
  	  	  month, day = month_day(name, element)
  	  	when 1
  	  	  if element.children.size > 3
  	  	  	next
  	  	  end
  	  	  puts element
  	  	  puts element.text
  	  	end
  	  end
  	end
  end

end