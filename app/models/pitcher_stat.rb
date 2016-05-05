class PitcherStat < ActiveRecord::Base
  belongs_to :lancer

  def ip_math
  	ip.to_i + (10 * ip.modulo(1))/3
  end

  def outs
  	(ip_math * 3).to_i
  end

  def tld
  	line_drives = ((outs+h)*ld/100).to_i + bb
  	all = (outs + h + bb)
  	tld = ((line_drives.to_f/all.to_f).round(3) * 100).round(1)
  	tld.nan? ? 0.0 : tld
  end

end