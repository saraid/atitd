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

    DAYS_PER_SEASON = 120
    DAYS_PER_YEAR = 360

    SEASONS = %w( Akhet Peret Shemu )
    MONTHS = %w( I II III IV )
    MERIDIANS = %w( AM PM )

    def self.fetch
      new(*open(TABTIME).read.chomp.split("\t")).tap do |time|
        time.real_time = Time.now
      end
    end

    def self.now
      fetch
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
      %i[ @year @day @hour @minute ].
        each { |var| instance_variable_set(var, instance_variable_get(var).to_i) }
      @second = (@timestamp || 0) % SECONDS_PER_MINUTE
      @meridian ||= MERIDIANS.first
      @drift = @drift.to_f if @drift

      @timestamp ||=
        [@year * SECONDS_PER_YEAR, SEASONS.index(@season) * SECONDS_PER_SEASON,
         MONTHS.index(@month) * SECONDS_PER_MONTH, @day * SECONDS_PER_DAY,
         @hour * SECONDS_PER_HOUR, @minute * SECONDS_PER_MINUTE, @second].
         reduce(0) { |sum, n| sum + n }
      @timestamp = @timestamp.to_i
    end
    attr_reader :drift
    attr_accessor :real_time

    def from_server?
      @drift && @real_time
    end

    def to_i
      @timestamp.to_i
    end

    def <=>(other)
      to_i <=> other.to_i
    end

    def to_s
      hour = @hour.zero? ? '12' : @hour
      "Year #{@year}, #{@season} #{@month}-#{@day}, #{hour}:#{'%02d' % @minute} #{@meridian}"
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

    def week
      @week ||=
        begin
          days = 0;
          days += (@year-1) * 360;
          days += case @season
                    when 'Akhet' then 0;
                    when 'Peret' then 120;
                    when 'Shemu' then 240;
                  end
          days += case @month
                    when 'I' then 0
                    when 'II' then 30
                    when 'III' then 60
                    when 'IV' then 90
                  end
          days += @day-1;
          (days / 7).floor
        end
    end
  end
end

require_relative 'egypt/duration'
