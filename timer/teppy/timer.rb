module ATITD
  class TeppyTimer
    def initialize(duration)
      @start = EgyptTime.fetch
      @real = Time.now
      @drift = @start.drift / 3

      @duration = duration
      @slept = 0

      @predictions = []
    end

    def create_drift_checkpoints!(minimum_interval = 1.teppy.minute)
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
        @drift = @current.drift
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
