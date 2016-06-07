class CreateBatterStats < ActiveRecord::Migration
  def change
    create_table :batter_stats do |t|
      t.belongs_to :batter,      index: true
      t.string   :handedness,    default: ""
      t.string   :range,         default: ""
      t.integer  :woba,          default: 0
      t.integer  :ops,		       default: 0
      t.integer  :ab,            default: 0
      t.integer  :so,            default: 0
      t.integer  :bb,            default: 0
      t.integer  :sb,            default: 0
      t.float 	 :fb, 		       default: 0.0
      t.float 	 :gb, 		       default: 0.0
      t.float    :ld,            default: 0.0
      t.integer  :wrc,           default: 0
      t.integer  :obp,           default: 0
      t.integer  :slg,           default: 0
      t.timestamps
    end
  end
end
