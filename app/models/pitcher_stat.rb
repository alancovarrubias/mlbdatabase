class PitcherStat < ActiveRecord::Base
  belongs_to :lancer

  def tld
  end

  def self.whoo
  	all.map{|pitcher| pitcher.ip }.sum
  end

end