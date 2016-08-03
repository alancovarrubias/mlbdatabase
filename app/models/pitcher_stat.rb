class PitcherStat < ActiveRecord::Base
  belongs_to :lancer

  def ip_math
  	ip.to_i + (10 * ip.modulo(1))/3
  end

  def outs
  	(ip_math * 3).round
  end

  def tld
    a = outs + h - so
    z = (a*ld/100).round
  	true_line_drives = z + bb
    tld = ((true_line_drives.to_f/(outs + h + bb).to_f).round(3) * 100).round(1)
  	tld.nan? ? 0.0 : tld
  end

end