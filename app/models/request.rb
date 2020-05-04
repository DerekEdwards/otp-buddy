class Request < ActiveRecord::Base

  #serialize :otp_response_body

  belongs_to :trip
  has_many :itineraries
  attr_accessor :otp_response, :parsed_body

  def plan
    otp_service = OTPService.new
    otp_mode = otp_service.get_otp_mode(self.trip_type)
    otp_request, @otp_response = otp_service.plan([self.trip.origin.lat, self.trip.origin.lng],
                                                 [self.trip.destination.lat, self.trip.destination.lng],
                                                 self.trip.scheduled_time, self.trip.arrive_by, otp_mode, wheelchair=false,
                                                 self.trip.walk_mph, self.trip.max_walk_miles, self.trip.max_bike_miles, self.trip.optimize,
                                                 self.trip.num_itineraries, self.trip.min_transfer_seconds, self.trip.max_transfer_seconds,
                                                 self.trip.banned_routes,self.trip.preferred_routes,self.trip.trip_shown_range_time,self.trip.locale,
                                                 self.trip.flex_use_reservation_services, self.trip.flex_use_eligibility_services, 
                                                 self.trip.max_pretransit_time)
    
    self.otp_request = otp_request
    self.otp_response_code = @otp_response.code
    self.otp_response_message = @otp_response.message
    self.save

    if @otp_response.code == "200"
      body = @otp_response.body
      #self.otp_response_body = JSON.parse(body)
      @parsed_body = JSON.parse(body)
      self.save
      create_itineraries JSON.parse(body).to_hash['plan']
    end

  end

  def create_itineraries plan

    return if plan.nil? 

    plan['itineraries'].collect do |itinerary_hash|
      itinerary = Itinerary.new
      itinerary.request = self
      itinerary.duration = itinerary_hash['duration'].to_f # in seconds
      itinerary.walk_time =  itinerary_hash['walkTime']
      itinerary.transit_time = itinerary_hash['transitTime']
      itinerary.wait_time = itinerary_hash['waitingTime']
      itinerary.transfers = fixup_transfers_count(itinerary_hash['transfers'])
      itinerary.walk_distance = itinerary_hash['walkDistance']
      itinerary.start_time = Time.at((itinerary_hash['startTime']).to_f/1000).in_time_zone("UTC")
      itinerary.end_time = Time.at((itinerary_hash['endTime']).to_f/1000).in_time_zone("UTC")
      itinerary.json_legs = fixup_legs itinerary_hash['legs'] || []
      itinerary.fare = itinerary_hash['fare']
      itinerary.server_status = 200
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
      unless leg['intermediateStops'].blank?
        trip_time = get_trip_time leg['tripId']
        unless trip_time.blank?
          stop_times = trip_time['stopTimes']
          leg['intermediateStops'].each do |stop|
            stop_time = stop_times.detect{|hash| hash['stopId'] == stop['stopId']}
            stop['realtimeArrival'] = stop_time['realtimeArrival']
            stop['realtimeDeparture'] = stop_time['realtimeDeparture']
            stop['arrivalDelay'] = stop_time['arrivalDelay']
            stop['departureDelay'] = stop_time['departureDelay']
            stop['realtime'] = stop_time['realtime']

          end
       end
      end

      #3 If a location is a ParkNRide Denote it
      if leg['mode'] == 'CAR' and self.trip_type == 'mode_park_transit'
        leg['to']['parkAndRide'] = true
      end

    end

    legs

  end

  def fixup_transfers_count(transfers)
    transfers == -1 ? nil : transfers
  end

  #Get the list of stops for this trip with realtime info
  def get_trip_time trip_id
    if @parsed_body.nil? or @parsed_body['tripTimes'].nil?
      return nil
    end
    trip_times = @parsed_body['tripTimes']
    return trip_times.detect{|hash| hash['tripId'] == trip_id}
  end

  def error_text
    if @parsed_body and @parsed_body["error"]
      return @parsed_body["error"]["msg"]
    else
      return nil
    end
  end

  def alerts
    if @parsed_body and @parsed_body["plan"]
      return @parsed_body["plan"]["alerts"]
    else
      return nil
    end
  end


end
