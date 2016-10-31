class Place < ActiveRecord::Base

  serialize :types
  serialize :address_components_raw


  def build_place_details_hash
    #Based on Google Place Details
    {
        address_components: self.address_components_raw,

        formatted_address: self.address,
        place_id: self.google_place_id,
        geometry: {
            location: {
                lat: self.lat,
                lng: self.lng,
            }
        },

        id: self.id,
        name: self.name,
        scope: "user",
        stop_code: self.stop_code,
        types: self.types
    }
  end

  #Build a new trip place from PlacesDetails element
  def from_place_details details

    components = details[:address_components]
    unless components.nil?
      components.each do |component|
        types = component[:types]
        if types.nil?
          next
        end
        if 'street_address'.in? types
          self.address = component[:long_name]
        elsif 'route'.in? types
          self.route = component[:long_name]
        elsif 'street_number'.in? types
          self.street_number = component[:long_name]
        elsif 'administrative_area_level_1'.in? types
          self.state = component[:long_name]
        elsif 'locality'.in? types
          self.city = component[:long_name]
        elsif 'postal_code'.in? types
          self.zip = component[:long_name]
        end
      end
    end

    self.raw_address = details[:formatted_address]
    self.lat = details[:geometry][:location][:lat]
    self.lng = details[:geometry][:location][:lng]
    self.name = details[:name]
    self.google_place_id = details[:place_id]
    self.stop_code = details[:stop_code]
    self.types = details[:types]
    self.address_components_raw  = details[:address_components]

    if self.raw_address.nil?
      self.raw_address = self.name
    end

    self.save

  end
end
