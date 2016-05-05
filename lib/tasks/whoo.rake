namespace :whoo do
  
  task test: :environment do
  	include NewShare
  	url = "http://api.wunderground.com/api/032ba78c0f4cfc2a/conditions/q/CA/San_Francisco.html"
  	w_api = Wunderground.new("032ba78c0f4cfc2a")
  	puts w_api.forecast_for("WA","Spokane")
  end

  task hi: :environment do
  	include NewShare
  	url = "http://www.wfmz.com/weather/hourbyhour/121266"
  	doc = download_document(url)
  	doc.css(".data").each do |stat|
  		puts stat
  	end
  end

end