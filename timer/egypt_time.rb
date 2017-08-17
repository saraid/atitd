require 'open-uri'
require 'active_support/duration'
require 'active_support/core_ext/numeric/time'

module ATITD
  class EgyptTime
    TABTIME = 'http://armeagle.atitd.org/tabtime.php'

    SECONDS_PER_MINUTE = 60
    MINUTES_PER_HOUR = 60
    HOURS_PER_MERIDIAN = 12
    MERIDIANS_PER_DAY = 2
    DAYS_PER_MONTH = 30
    MONTHS_PER_SEASON = 4
    SEASONS_PER_YEAR = 3

    SECONDS_PER_HOUR = 3600
    SECONDS_PER_MERIDIAN = 43200
    SECONDS_PER_DAY = 86400
    SECONDS_PER_WEEK = 604800
    SECONDS_PER_MONTH = 2592000
    SECONDS_PER_SEASON = 10368000
    SECONDS_PER_YEAR = 31104000

    SEASONS = %w( Akhet Peret Shemu )
    MONTHS = %w( I II III IV )
    MERIDIANS = %w( AM PM )

    def self.fetch
      new(*open(TABTIME).read.chomp.split("\t")).tap do |time|
        time.real_time = Time.now
      end
    end

    def self.from_timestamp(timestamp)
      new(*
        [ :year, :season, :month, :day, :meridian, :hour, :minute ].each_with_object({
          arguments: [],
          remainder: 0
        }) do |part, memo|
          memo[:arguments] << (timestamp - memo[:remainder]) / const_get(:"SECONDS_PER_#{part.upcase}")
          memo[:remainder] += const_get(:"SECONDS_PER_#{part.upcase}") * memo[:arguments].last
        end[:arguments].tap do |parts|
          parts[1] = SEASONS[parts[1]]
          parts[2] = MONTHS[parts[2]]
          parts << MERIDIANS[parts.delete_at(4)]
        end.<<(timestamp)
      )
    end

    def initialize(*parts)
      @year, @season, @month, @day, @hour, @minute, @meridian, @timestamp, @drift, @server = parts
      %i[ @year @day @hour @minute @timestamp ].
        each { |var| instance_variable_set(var, instance_variable_get(var).to_i) }
      @second = @timestamp % SECONDS_PER_MINUTE
      @drift = @drift.to_f if @drift
    end
    attr_reader :drift
    attr_accessor :real_time

    def from_server?
      @drift && @real_time
    end

    def to_i
      @timestamp
    end

    def to_s
      "Year #{@year}, #{@season} #{@month}-#{@day}, #{@hour}:#{@minute} #{@meridian}"
    end

    def +(other)
      case other
      when Duration then self.class.from_timestamp(@timestamp + other.to_i)
      when Numeric then self.class.from_timestamp(@timestamp + other)
      when ActiveSupport::Duration then add_duration(other)
      end
    end

    def -(other)
      self + -other
    end
  end
end
