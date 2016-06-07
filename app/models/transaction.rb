class Transaction < ActiveRecord::Base
  belongs_to :player
  belongs_to :team

  def set_active
  	
  end

end
