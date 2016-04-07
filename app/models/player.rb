class Player < ActiveRecord::Base
  validates :name,        uniqueness: :true, allow_blank: true
  validates :identity,    uniqueness: :true, allow_blank: true
  validates :fangraph_id, uniqueness: :true, allow_nil: true
  has_many :batter_stats
  has_many :pitcher_stats

end
