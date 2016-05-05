class BatterStat < ActiveRecord::Base
  belongs_to :batter

  def tld
  	tld = ((ld/100 * ab + bb) / (bb + ab) * 100).round(1)
  	tld.nan? ? 0 : tld
  end

end
