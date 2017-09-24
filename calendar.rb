require 'icalendar'
require 'nokogiri'
require 'open-uri'
require 'forwardable'

module ATITD
  class Calendar
    extend Forwardable

    def_delegator :@calendar, :to_ical
    attr_reader :calendar

    def initialize
      @calendar = Icalendar::Calendar.new

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
  end
end

require 'rack'

def application(env)
  path = env['REQUEST_PATH']
  type =
    case path
      when /\.css$/ then 'text/css'
      when /\.js$/ then 'text/javascript'
      when /\.ico$/ then return [404, {'Content-Type' => "text/plain"}, '']
      when /\.jpg$/ then 'image/jpeg'
      when /\.ics$/ then 'text/calendar'
      else 'text/html'
    end

  path =
    case path
      when '/' then '/index.html'
      when '/atitd/calendar.ics'
        load 'calendar.rb'
        return [200, {'Content-Type' => type}, ATITD::Calendar.new.to_ical]
      else path
    end
  data = File.open(Dir.pwd + path) { |f| f.read }
  [200, {'Content-Type' => type}, data]
end

Rack::Handler::Thin.run method(:application), :Port => 1337
