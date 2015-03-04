require 'net/http'
require 'icalendar'
require 'open-uri'

# List of calendars
#
# Format:
#   <name> => <uri>
# Example:
#   hangouts: "https://www.google.com/calendar/ical/<hash>.calendar.google.com/private-<hash>/hangouts.ics"
calendars = {Public_Pivotal_Seattle_Events: "https://www.google.com/calendar/ical/pivotal.io_qgrlap9ooml7tojb6i3rou6dag%40group.calendar.google.com/private-3dc39bd4e4c0d9e7c019e3581085958f/basic.ics"}

SCHEDULER.every '1m', :first_in => 0 do |job|
    
    calendars.each do |cal_name, cal_uri|
        
        ics  = open(cal_uri) { |f| f.read }
        cal = Icalendar.parse(ics).first
        
        # puts cal.to_ical
        events = cal.events
        
        # select only current and upcoming events
        now = Time.now.utc
        events = events.select{ |e| e.dtend.to_time.utc > now }
        
        # sort by start time
        events = events.sort{ |a, b| a.dtstart.to_time.utc <=> b.dtstart.to_time.utc }[0..1]
        
        events = events.map do |e|
            {
                title: e.summary,
                start: e.dtstart.to_time.to_i,
                end: e.dtend.to_time.to_i
            }
        end
        
        send_event("google_calendar_#{cal_name}", {events: events})
    end
    
end