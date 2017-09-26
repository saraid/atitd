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
      else path
    end
  data = File.open(Dir.pwd + path) { |f| f.read }
  [200, {'Content-Type' => type}, data]
end

Thread.new do
  require 'active_support/core_ext/numeric/date'
  loop do
    File.open('atitd_calendar.ics') { |f| f.write(ATITD::Calendar.new.to_ical) }
    sleep 6.minutes
  end
end

Rack::Handler::Thin.run method(:application), :Port => 1337

