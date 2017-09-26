require 'icalendar'
require 'forwardable'

require 'nokogiri'
require 'open-uri'
require_relative 'timer/egypt_week'

module ATITD
  class Calendar
    extend Forwardable

    def_delegator :@calendar, :to_ical
    attr_reader :calendar

    def initialize
      @calendar = Icalendar::Calendar.new

      add_events!
      add_weeks!
    end

    def add_events!
      Nokogiri::HTML(open('http://www.atitd.com/events.html').read).
        css('h5 font').map do |html|
          @calendar.event do |e|
            header = html.children.first.text
            time, place = html.css('em').map(&:text)
            description = html.css('span').text

            e.summary = header
            e.dtstart = DateTime.parse(time)
            e.location = place
            e.description = description
          end
        end
    end

    def add_weeks!
      now = EgyptTime.now
      (now.week..now.week+5).map(&EgyptWeek.method(:of)).each do |week|
        week.estimate_real_time_from(now)
      end.each do |week|
        real = week.in_real_time
        @calendar.event do |e|
          e.summary = "Week #{week.to_i}"
          e.dtstart = real.begin
          e.dtend = real.end
        end
      end
    end
  end
end

puts ATITD::Calendar.new.to_ical if __FILE__ == $0
