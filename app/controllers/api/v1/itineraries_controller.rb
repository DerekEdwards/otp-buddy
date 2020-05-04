module Api
  module V1
    class ItinerariesController < Api::V1::ApiController

      def plan

        # TODO find out why waypoints in arrive by trips are emailing the second segment then the first.
        # Some insight be found by seeing Judy's changes to the old 1 Click system
        # https://github.com/rideRTD/otp-trip-manager/blob/master/app/controllers/itineraries_controller.rb

        #Unpack params
        modes = params['modes'] || ['mode_transit']
        trip_parts = params[:itinerary_request]
        trip_token = params[:trip_token]
        optimize = params[:optimize]
        max_walk_miles = params[:max_walk_miles]
        max_bike_miles = params[:max_bicycle_miles] # Miles
        max_walk_seconds = params[:max_walk_seconds] # Seconds
        walk_mph = params[:walk_mph] || 3.0
        min_transfer_time = params[:min_transfer_time_hard]
        max_transfer_time = params[:max_transfer_time]
        trip_shown_range_time = params[:trip_shown_range_time]
        banned_routes = params[:banned_routes]
        preferred_routes = params[:preferred_routes]
        locale = params[:locale] || "en"
        flex_use_reservation_services = params[:flex_use_reservation_services]
        flex_use_eligibility_services = params[:flex_use_eligibility_services]
        max_pretransit_time = params[:max_pretransit_time] || 1800

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
        # TODO Derek is it worth adding this to the database? RTD isn't currently logging it.
        #trip.trip_shown_range_time = trip_shown_range_time.nil? ? nil : trip_shown_range_time.to_i
        trip.trip_shown_range_time = trip_shown_range_time.nil? ? nil : trip_shown_range_time.to_i
        trip.source_tag = source_tag
        trip.locale = locale 
        trip.flex_use_reservation_services = flex_use_reservation_services
        trip.flex_use_eligibility_services = flex_use_eligibility_services
        trip.max_pretransit_time = max_pretransit_time

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
        trip.scheduled_time = trip_part[:trip_time].to_datetime.in_time_zone

        #If we are banning or preferring routes, get the list of feed ids
        feed_ids  = []
        unless banned_routes.blank? and preferred_routes.blank?
          feed_ids = OTPService.new.get_all_feed_ids
        end

        #Set Banned Routes
        unless banned_routes.blank?
          banned_routes_string = ""
          banned_routes.each do |banned_route|
            feed_ids.each do |feed_id|
              banned_routes_string +=  feed_id.to_s + '_' + banned_route['short_name'] + ','
            end
          end
          trip.banned_routes = banned_routes_string.chop
        end

        #Set Preferred Routes
        unless preferred_routes.blank?
          preferred_routes_string = ""
          preferred_routes.each do |preferred_route|
            feed_ids.each do |feed_id|
              preferred_routes_string += feed_id.to_s + '_' + preferred_route['short_name'] + ','
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

        render status: 200, json: {trip_id: trip.id, origin: trip.origin.build_place_details_hash, destination: trip.destination.build_place_details_hash, 
          origin_in_callnride: origin_in_callnride, origin_callnride: origin_callnride, 
          destination_in_callnride: destination_in_callnride, destination_callnride: destination_callnride, 
          trip_token: trip.token, errors: trip.errors_hash, alerts: trip.alerts_hash, 
          itineraries: trip.itineraries.map{ |i| i.serialized }}


        trip.save

      end #Plan

      #Itinerary email template is out of date.
      def email
        email_itineraries = params[:email_itineraries]
        trip_link = params[:trip_link].nil? ? nil : params[:trip_link]

        email_itineraries.each do |email_itinerary|
          email_addresses = email_itinerary[:email_addresses]
          subject = email_itinerary[:subjectLine]
          ids = email_itinerary[:itineraries].collect { |x| x[:id].to_i }

          #get the itineraries and ensures that they are retuned in the same order they were requested
          itineraries = Itinerary.find(ids).index_by(&:id).values_at(*ids)

          # for subject, get first trip
          trip = itineraries.first.request.trip

          if subject.blank?
            if trip.scheduled_time > Time.now
              subject = "Your Upcoming Ride on " + trip.scheduled_time.strftime('%_m/%e/%Y').gsub(" ","")
            else
              subject = "Your Ride on " + trip.scheduled_time.strftime('%_m/%e/%Y').gsub(" ","")
            end
          end

          UserMailer.user_itinerary_email(email_addresses, itineraries, subject, trip_link=nil).deliver

        end

        render json: {result: 200}

      end #Email

    end #Itineraries Controller
  end #V1
end #API
