require 'rest-client'
require 'json'

url = "https://api.weathersource.com/v1/bd511e5eeb837ddb1c4e/history_by_postal_code.json?period=hour&postal_code_eq=22222&country_eq=US&timestamp_eq=2012-02-10T00:00:00-05:00&fields=postal_code,country,timestamp,temp,precip,windSpd,dewPt,feelsLike,relHum,sfcPres,spcHum"
response = RestClient.get(url)
hash = JSON.parse(response)[0]
puts hash