require 'rack'
require 'logger'

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
      else path
    end
  data = File.open(Dir.pwd + path) { |f| f.read }
  [200, {'Content-Type' => type}, data]
end

Thread.new do
  Thread.abort_on_exception = true
  logger = Logger.new(STDOUT)

  CALENDAR_FILE = 'atitd_calendar.ics'
  # Updates to game time occur every 15 game minutes.
  # But I don't anticipate any meaningful changes within a 6-hour period.
  TIMEOUT_PERIOD = 6.hours

  load 'calendar.rb'
  require 'active_support/core_ext/numeric/time'
  loop do
    logger.info "Waking; constructing a new Calendar"
    File.open(CALENDAR_FILENAME, 'w') { |f| f.write(ATITD::Calendar.new.to_ical) }
    logger.info "Wrote to #{CALENDAR_FILENAME}; sleeping for #{TIMEOUT_PERIOD}"
    sleep TIMEOUT_PERIOD
  end
end

Rack::Handler::Thin.run method(:application), :Port => 1337

