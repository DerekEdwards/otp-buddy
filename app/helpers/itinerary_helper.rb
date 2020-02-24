module ItineraryHelper
  # This module helps objects speak like a human and not like a computer

  METERS_TO_MILES = 0.000621371192

  def humanized_origin
    origin = self.request.trip.origin
    return humanized_place origin
  end

  def humanized_destination
    destination = self.request.trip.destination
    return humanized_place destination
  end

  def humanized_place place
    return place.name if place.name
    return "#{place.address}, #{place.city}, #{place.state}"
  end

  def humanized_start_time
    return format_time self.start_time
  end

  def humanized_end_time
    return format_time self.end_time
  end

  def format_time(time)
    time.strftime('%l:%M %p').strip
  end

  def humanized_duration options={}
    return humanized_time_in_seconds self.duration, options
  end

  def humanized_walk_time options={}
    return humanized_time_in_seconds self.walk_time, options
  end

  def humanized_time_in_seconds(time_in_seconds, options = {})

    time_in_seconds = time_in_seconds.to_i
    hours = time_in_seconds/3600
    minutes = (time_in_seconds - (hours * 3600))/60

    time_string = ''

    if time_in_seconds > 60*60*24 and options[:days_only]
      count = hours / 24
      return count.to_s + " " + "Day"
    end

    if hours > 0
      time_string << hours.to_s + " " + "hour "
    end

    if minutes > 0 || (hours > 0 and !options[:suppress_minutes])
      time_string << minutes.to_s + " " + "min"
      time_string << "s" if minutes != 1
    end

    if time_in_seconds < 60
      time_string = "less than 1 minute"
    end

    if options[:days_only]
      time_string = (hours/24.round).to_s + " day"
    end

    time_string
  end

  def humanized_duration_description leg
    start_time = otp_time_to_datetime leg['startTime']
    end_time = otp_time_to_datetime leg['endTime']

    format_time(start_time) + ' to ' + format_time(end_time)

  end

  def humanized_distance_from_leg leg

    return self.exact_distance_to_words leg['distance']

  end

  def otp_time_to_datetime otp_time
    # Time.at(otp_time.to_f/1000).in_time_zone("UTC")
    Time.at(otp_time.to_f/1000).in_time_zone("Mountain Time (US & Canada)")
  end

  def leg_steps leg
    html = "<div data-toggle='collapse' data-target='#drivingDirections'><a class='drivingDirectionsLink'>" + self.short_description(leg) + "</a></div><div id='drivingDirections' class='panel-body collapse'>"

    leg['steps'].each do |hash|
      html << "<p>"
      html << hash["relativeDirection"].to_s.humanize
      html << " on to "
      html << hash["streetName"].to_s
      html << ", "
      html << (hash["distance"] * 0.000621371).round(2).to_s
      html << "miles </br></p>"
    end

    html << "</div>"
    return html.html_safe
  end

  def short_description leg

    case leg['mode']
      when 'WALK'
        return "Walk to " + leg['to']['name']
      when 'BICYCLE'
        return "Bicycle to " + leg['to']['name']
      when 'CAR'
        return "Drive to " + leg['to']['name']
      when 'TRAM', 'SUBWAY', 'RAIL', 'BUS', 'FERRY', 'CABLE_CAR', 'GONDOLA', 'FUNICULAR'
        if(leg['mode'] == 'TRAM')
          mode = 'Train'
        else
          mode = leg['mode'].humanize
        end
        agency = leg['agencyName']
        route_name = leg['routeShortName'] || leg['routeLongName']

        if leg['headsign']
          return [agency, leg['route'], mode, leg['headsign'], 'to', leg['to']['name']].join(' ')
        else
          return [agency, leg['route'], mode, 'to', leg['to']['name']].join(' ')
        end

      else
        return leg['mode'].humanize

    end

  end

  def exact_distance_to_words(dist_in_meters)
    return '' unless dist_in_meters

    # convert the meters to miles
    miles = dist_in_meters * METERS_TO_MILES
    if miles < 0.001
      dist_str = [miles.round(4).to_s, 'miles'].join(' ')
    elsif miles < 0.01
      dist_str = [miles.round(3).to_s, 'miles'].join(' ')
    else
      dist_str = [miles.round(2).to_s, 'miles'].join(' ')
    end

    dist_str
  end

  def get_mode_icon_from_leg leg
    return get_mode_icon leg['mode']
  end

  def get_mode_icon mode
    return "#{Setting.host}/assets/modes/#{mode.downcase}.png"
  end

  def alerts_array
    alerts = [] 
    self.json_legs.each do |leg|
      if leg["alerts"]
        alerts << leg["alerts"]
      end
    end
    return alerts
  end

  def mode_array
    modes = []
    self.json_legs.each do |leg|
      if leg["mode"]
        modes << leg["mode"]
      end
    end
    modes.uniq
  end

end #Module