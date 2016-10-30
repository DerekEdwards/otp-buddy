class Request < ActiveRecord::Base

  belongs_to :trip
  has_many :itineraries

  def plan
    otp_service = OTPService.new
    otp_request, otp_response = otp_service.plan([self.trip.origin.lat, self.trip.origin.lng],[self.trip.destination.lat, self.trip.destination.lng], Time.now + 2.hours)
    self.otp_request = otp_request
    self.otp_response_code = otp_response.code
    self.otp_response_message = otp_response.message
    self.save

    if otp_response.code == "200"
      body = otp_response.body
      self.otp_response_body = body
      self.save
      create_itineraries JSON.parse(body).to_hash['plan']
    end

  end

  def create_itineraries plan
    plan['itineraries'].collect do |itinerary_hash|
      itinerary = Itinerary.new
      itinerary.request = self
      itinerary.duration = itinerary_hash['duration'].to_f # in seconds
      itinerary.walk_time =  itinerary_hash['walkTime']
      itinerary.transit_time = itinerary_hash['transitTime']
      itinerary.wait_time = itinerary_hash['waitingTime']
      itinerary.transfers = fixup_transfers_count(itinerary_hash['transfers'])
      itinerary.walk_distance = itinerary_hash['walkDistance']
      itinerary.json_legs = fixup_legs itinerary_hash['legs'] || []
      itinerary.save
    end
  end

  def fixup_legs legs

    legs.each do |leg|
      #1 Check to see if this route_type is classified as a special route_type

      specials = Setting.gtfs_special_route_types
      if leg['routeType'].nil?
        leg['specialService'] = false
      else
        leg['specialService'] = leg['routeType'].in? specials
      end

      #2 Check to see if real-time is available for node stops
      #unless leg['intermediateStops'].blank?
      #  trip_time = OTPService.new.get_trip_time leg['tripId']
      #  unless trip_time.blank?
      #    stop_times = trip_time['stopTimes']
      #    leg['intermediateStops'].each do |stop|
      #      stop_time = stop_times.detect{|hash| hash['stopId'] == stop['stopId']}
      #      stop['realtimeArrival'] = stop_time['realtimeArrival']
      #      stop['realtimeDeparture'] = stop_time['realtimeDeparture']
      #      stop['arrivalDelay'] = stop_time['arrivalDelay']
      #      stop['departureDelay'] = stop_time['departureDelay']
      #      stop['realtime'] = stop_time['realtime']
      #
      #    end
      # end
      #end

      #3 If a location is a ParkNRide Denote it
      if leg['mode'] == 'CAR' and itinerary.returned_mode_code == Mode.park_transit.code
        leg['to']['parkAndRide'] = true
      end

    end

    legs

  end

  def fixup_transfers_count(transfers)
    transfers == -1 ? nil : transfers
  end

end
