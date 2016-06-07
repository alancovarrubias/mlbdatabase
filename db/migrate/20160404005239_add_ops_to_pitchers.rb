class AddOpsToPitchers < ActiveRecord::Migration
  def change
    add_column(:pitchers, :OPS_L, :integer, default: 0.0)
  	add_column(:pitchers, :OPS_R, :integer, default: 0.0)
  	add_column(:pitchers, :OPS_previous_L, :integer, default: 0.0)
  	add_column(:pitchers, :OPS_previous_R, :integer, default: 0.0)
  end
end
