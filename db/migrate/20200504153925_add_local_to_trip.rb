class AddLocalToTrip < ActiveRecord::Migration
  def change
    add_column :trips, :locale, :string, default: "en"
  end
end
