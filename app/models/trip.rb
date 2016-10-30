class Trip < ActiveRecord::Base

  #Associations
  belongs_to :origin, class_name: 'Place', foreign_key: "origin_id"
  belongs_to :destination, class_name: 'Place', foreign_key: "destination_id"
end
