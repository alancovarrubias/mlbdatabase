ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  protected
  def test_for_db_error(error_message, &block)
    begin
      yield
    rescue ActiveRecord::StatementInvalid
      database_threw_error = true
    rescue
      something_else_threw_error = true
    end
    assert !something_else_threw_error, "There is an error in our test code"
    assert database_threw_error && !something_else_threw_error, error_message
  end
end
