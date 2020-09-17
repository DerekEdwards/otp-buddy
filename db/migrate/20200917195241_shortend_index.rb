class ShortendIndex < ActiveRecord::Migration
  def change
    rename_index :itineraries, 'index_itineraries_on_request_id', 'idx_itins_on_request_id'
  end
end
