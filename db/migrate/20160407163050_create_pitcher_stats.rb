class CreatePitcherStats < ActiveRecord::Migration
  def change
    create_table :pitcher_stats do |t|
      t.belongs_to :lancer,		   index: true
      t.string     :handedness,  default: ""
      t.string     :range,       default: ""
      t.float      :whip,        default: 0.0
      t.float      :ip,          default: 0.0
      t.integer    :so,          default: 0
      t.integer    :bb,          default: 0
      t.integer    :fip,         default: 0
      t.float      :xfip,        default: 0.0
      t.float      :kbb,         default: 0.0
      t.integer    :woba,        default: 0
      t.integer    :ops,         default: 0
      t.float      :era,         default: 0.0
      t.float      :fb,          default: 0.0
      t.float	     :gb, 		     default: 0.0
      t.float      :ld,          default: 0.0
      t.timestamps
    end
  end
end
