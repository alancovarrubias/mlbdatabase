# require 'rest-client'
require 'json'

THOUGHTBOT_REPOS_ENDPOINT = "https://api.github.com/users/thoughtbot/repos"

def main
	response = `curl #{THOUGHTBOT_REPOS_ENDPOINT}`
	puts JSON.parse(response)
end

main