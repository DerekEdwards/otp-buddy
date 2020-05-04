class AddFlexAttributesToTrip < ActiveRecord::Migration
  def change
    add_column :trips, :flex_use_reservation_services, :boolean, default: true 
    add_column :trips, :flex_use_eligibility_services, :boolean, default: true 
    add_column :trips, :max_pretransit_time, :integer, default: 1800
  end
end
