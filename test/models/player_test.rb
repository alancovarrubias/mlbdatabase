require 'test_helper'

class PlayerTest < ActiveSupport::TestCase

  test "should not save without name" do
  	player = Player.new
  	test_for_db_error("Database did not catch null name") do
  	  player.save
  	end
  end
end
