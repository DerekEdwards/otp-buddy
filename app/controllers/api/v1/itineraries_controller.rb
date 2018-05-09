module Api
  module V1
    class ItinerariesController < Api::V1::ApiController

      def plan

        #Unpack params
        modes = params['modes'] || ['mode_transit']
        trip_parts = params[:itinerary_request]
        trip_token = params[:trip_token]
        optimize = params[:optimize]
        max_walk_miles = params[:max_walk_miles]
        max_bike_miles = params[:max_bicycle_miles] # Miles
        max_walk_seconds = params[:max_walk_seconds] # Seconds
        walk_mph = params[:walk_mph] || 3.0
        min_transfer_time = params[:min_transfer_time]
        max_transfer_time = params[:max_transfer_time]
        banned_routes = params[:banned_routes]
        preferred_routes = params[:preferred_routes]

        source_tag = params[:source_tag]


        #Assign Meta Data
        trip = Trip.new
        trip.token = trip_token
        trip.optimize = optimize || "TIME"
        trip.max_walk_miles = max_walk_miles
        trip.max_walk_seconds = max_walk_seconds
        trip.walk_mph = walk_mph
        trip.max_bike_miles = max_bike_miles
        trip.num_itineraries = (params[:num_itineraries] || 3).to_i
        trip.min_transfer_seconds = min_transfer_time.nil? ? nil : min_transfer_time.to_i
        trip.max_transfer_seconds = max_transfer_time.nil? ? nil : max_transfer_time.to_i
        trip.source_tag = source_tag


        #Build the Trip Places
        origin = Place.new
        destination = Place.new
        first_part = (trip_parts.select { |part| part[:segment_index] == 0}).first
        origin.from_place_details first_part[:start_location]
        destination.from_place_details first_part[:end_location]
        trip.origin = origin
        trip.destination = destination

        trip_part = trip_parts.first
        trip.arrive_by = !(trip_part[:departure_type].downcase == 'depart')
        trip.scheduled_time = trip_part[:trip_time].to_datetime

        #Get the ID of the first feed.  If it's in the DB, grab it otherwise grab it from OTPService
        first_feed_id = Setting.first_feed_id ? Setting.first_feed_id : OTPService.new.get_first_feed_id

        #Set Banned Routes
        unless banned_routes.blank?
          banned_routes_string = ""
          banned_routes.each do |banned_route|
            if banned_route['id'].blank?
              banned_routes_string +=  first_feed_id.to_s + '_' + banned_route['short_name'] + ','
            else
              banned_routes_string += banned_route['id'].split(':').first + '_' + banned_route['short_name'] + ','
            end
          end
          trip.banned_routes = banned_routes_string.chop
        end

        #Set Preferred Routes
        unless preferred_routes.blank?
          preferred_routes_string = ""
          preferred_routes.each do |preferred_route|
            if preferred_route['id'].blank?
              preferred_routes_string += first_feed_id.to_s + '_' + preferred_route['short_name'] + ','
            else
              preferred_routes_string += preferred_route['id'].split(':').first + '_' + preferred_route['short_name'] + ','
            end

          end
          trip.preferred_routes = preferred_routes_string.chop
        end

        #Create a request for each Mode
        modes.each do |mode|
          request = Request.new
          request.trip_type = mode
          request.trip = trip
          request.save
        end

        trip.plan

        origin_in_callnride, origin_callnride = trip.origin.within_callnride?
        destination_in_callnride, destination_callnride = trip.destination.within_callnride?

        render status: 200, json: {trip_id: trip.id, origin: trip.origin.build_place_details_hash, destination: trip.destination.build_place_details_hash, origin_in_callnride: origin_in_callnride, origin_callnride: origin_callnride, destination_in_callnride: destination_in_callnride, destination_callnride: destination_callnride, trip_token: trip.token, itineraries: trip.itineraries.map{ |i| i.serialized }}


        trip.save
      end #Plan

      #Itinerary email template is out of date.
      def email
        email_itineraries = params[:email_itineraries]
        trip_link = params[:trip_link].nil? ? nil : params[:trip_link]

        email_itineraries.each do |email_itinerary|
          email_addresses = email_itinerary[:email_addresses]

          ids = email_itinerary[:itineraries].collect { |x| x[:id] }
          itineraries = Itinerary.where(id: ids)

          # for subject, get first trip
          trip = itineraries.first.request.trip

          if !email_itinerary[:subject].nil?
            subject = email_itinerary[:subject]
          elsif trip.scheduled_time > Time.now
            subject = "Your Upcoming Ride on " + trip.scheduled_time.strftime('%_m/%e/%Y').gsub(" ","")
          else
            subject = "Your Ride on " + trip.scheduled_time.strftime('%_m/%e/%Y').gsub(" ","")
          end

          UserMailer.user_itinerary_email(email_addresses, itineraries, subject, trip_link=nil).deliver

        end

        render json: {result: 200}

      end #Email

    end #Itineraries Controller
  end #V1
end #API
