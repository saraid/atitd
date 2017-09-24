require_relative './egypt_time'
require_relative './core_ext'

module ATITD
  class EgyptWeek < Range
    DAYS_PER_WEEK = 7

    def self.from_time(egypt_time)
      self.new(egypt_time.week).tap do |week|
        week.estimate_real_time_from(egypt_time) if egypt_time.real_time
      end
    end

    def self.now
      from_time(EgyptTime.now)
    end

    def self.of(num, using = nil)
      new(num).tap do |week|
        week.estimate_real_time_from(using) unless using.nil?
      end
    end

    def initialize(num)
      days = (num * DAYS_PER_WEEK) + 1
      year, remainder = days.divmod(EgyptTime::DAYS_PER_YEAR)
      season, remainder = remainder.divmod(EgyptTime::DAYS_PER_SEASON)
      month, days = remainder.divmod(EgyptTime::DAYS_PER_MONTH)

      @begin = EgyptTime.new(year.succ, EgyptTime::SEASONS[season], EgyptTime::MONTHS[month], days)
      @end = @begin + DAYS_PER_WEEK.egypt.days

      super(@begin, @end)
    end

    def inspect
      "#{@begin}..#{@end}"
    end

    def estimate_real_time_from(egypt_time)
      @begin.real_time = egypt_time.real_time + (@begin.to_i - egypt_time.to_i).
        egypt.seconds.to_real_duration(egypt_time.drift)
      @end.real_time = egypt_time.real_time + (@end.to_i - egypt_time.to_i).
        egypt.seconds.to_real_duration(egypt_time.drift)
    end

    def estimate_real_time!
      estimate_real_time_from(EgyptTime.now)
    end

    def in_real_time
      Range.new(@begin.real_time, @end.real_time)
    end
  end
end
