# frozen_string_literal
class UpdateSourceValues < ActiveRecord::Migration[7.0]
  def up
    Profile.update_all('balance = points_received')
    Tip.where(source: 'reaction').update_all(source: 'point_reaction')
    Tip.where(source: 'ditto').update_all(source: 'ditto_reaction')
    Tip.where(source: 'plusplus').update_all(source: 'inline')
  end

  def down
    # nope
  end
end
