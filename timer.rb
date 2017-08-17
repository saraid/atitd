require_relative 'timer/egypt_time'
require_relative 'timer/core_ext'
require_relative 'timer/egypt/duration'
require_relative 'timer/egypt/timer'
require_relative 'timer/teppy/duration'
require_relative 'timer/teppy/timer'

module ATITD
  class Timer
    def initialize(duration)
      @start = EgyptTime.fetch
      @real = Time.now
      @duration = duration
      @slept = 0

      @predictions = []

      if EgyptTime::Duration == duration.class
        @using = :egypt
        create_drift_checkpoints_for_egypt_time!
      elsif TeppyTime::Duration == duration.class
        @using = :teppy
        create_drift_checkpoints_for_teppy_time!
      else raise "#{duration.class} invalid!"
      end
      calculate_drift!(@start)
    end

    def calculate_drift!(server_time)
      @drift = server_time.drift
      @drift /= 3 if @using == :teppy
    end

    def create_drift_checkpoints_for_egypt_time!(minimum_interval = 1.egypt.minutes)
      return [@duration] if @duration <= minimum_interval
      recurse = lambda do |dur, memo|
        return memo if dur < minimum_interval
        recurse.call(dur / 2, memo << dur.egypt.seconds)
      end
      @checks = recurse.call(@duration, [])[1..-1]
    end

    def create_drift_checkpoints_for_teppy_time!(minimum_interval = 1.teppy.minutes)
      return [@duration] if @duration <= minimum_interval
      recurse = lambda do |dur, memo|
        return memo if dur < minimum_interval
        recurse.call(dur / 2, memo << dur.teppy.seconds)
      end
      @checks = recurse.call(@duration, [])[1..-1]
    end

    def start!
      @checks.each do |check|
        interval = check.to_real_duration(@drift)
        @predictions << (prediction = @real + @duration.to_real_duration(@drift))
        puts "Sleeping for #{interval.round(2)}s; Next check: #{Time.now + interval}; Prediction: #{prediction}; Current Drift: #{@drift}"
        sleep(interval)
        @slept = Time.now - @real
        @current = EgyptTime.fetch
        @drift_changed = @drift == @current.drift # TODO: Figure out how to use this to skip a check.
        calculate_drift!(@current)
      end
      interval = @duration.to_real_duration(@drift) - @slept
      puts "Sleeping for #{interval.round(2)}s; Next check: #{Time.now + interval}; Actual: #{@real + @duration.to_real_duration(@drift)}; Current Drift: #{@drift}"
      sleep(interval)
      @current = EgyptTime.fetch.tap { |x| puts x.to_s }.tap do |time|
        correct = Time.now
        puts "Prediction Quality: #{@predictions.map { |p| (correct - p).round(2) }}"
        puts "Actual time spent: #{(Time.now - @real).round(2)} seconds."
      end
    end
  end
end

module Test
  class << self
    def logger
      require 'logger'
      @logger ||= Logger.new(STDOUT)
    end

    def log_time(time)
      logger.info("#{time}; timestamp: #{time.to_i}")
    end

    def test(duration = 10.egypt.minutes)
      current_egypt_time = ATITD::EgyptTime.fetch
      log_time(current_egypt_time)
      interval = duration.to_real_duration(current_egypt_time.drift)
      logger.info("Waiting #{interval.round(2)} seconds, or #{duration.inspect}.")
      logger.info("Predicting #{Time.now + interval}, with timestamp: #{current_egypt_time.to_i + duration.to_i}")
      sleep interval
      advanced_egypt_time = ATITD::EgyptTime.fetch
      log_time(advanced_egypt_time)
      puts "Error: #{duration.to_i - (advanced_egypt_time.to_i - current_egypt_time.to_i)} egypt seconds."
    end
  end
end
