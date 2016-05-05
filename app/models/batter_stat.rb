class BatterStat < ActiveRecord::Base
  belongs_to :batter

  def tld
  	((ld/100 * ab + bb) / (bb + ab)).round(2)
  end

end
