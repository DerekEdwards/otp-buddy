class Place < ActiveRecord::Base

  serialize :types
  serialize :address_components_raw


  def build_place_details_hash
    #Based on Google Place Details
    {
        address_components: self.address_components_raw,

        formatted_address: self.address || self.raw_address,
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

    if self.name.nil?
      self.name = self.raw_address
    end

    self.save

  end

  def within_callnride?

    begin
      factory = RGeo::Geographic.simple_mercator_factory
      point = factory.point(self.lng.to_f, self.lat.to_f)
      Setting.callnride_boundary.each do |boundary|
        if boundary[:geometry].contains? point
          return true, boundary[:name]
        end
      end
      return false, nil
    rescue
      return false, nil
    end

  end

end
