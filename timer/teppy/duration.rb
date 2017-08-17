module ATITD
  module TeppyTime
    class ProtoDuration
      def initialize(value)
        @value = value
      end

      def seconds
        Duration.seconds(@value)
      end
      alias :second :seconds

      def minutes
        Duration.minutes(@value)
      end
      alias :minute :minutes

      def hours
        Duration.hours(@value)
      end
      alias :hour :hours
    end

    class Duration < ActiveSupport::Duration

      PARTS_IN_SECONDS = {
        seconds:  1,
        minutes:  60,
        hours:    60
      }
      PARTS = [:hours, :minutes, :seconds]

      def initialize(value, parts)
        @value, @parts = value, parts.to_h
        @parts.default = 0
      end

      def inspect #:nodoc:
        parts.
          reduce(::Hash.new(0)) { |h, (l, r)| h[l] += r; h }.
          sort_by { |unit,  _ | PARTS.index(unit) }.
          map     { |unit, val| "#{val} teppy #{val == 1 ? unit.to_s.chop : unit.to_s}" }.
          to_sentence(locale: ::I18n.default_locale)
      end

      class << self
        def seconds(value)
          new(value, [[:seconds, value]])
        end

        def minutes(value)
          new(value * 60, [[:minutes, value]])
        end

        def hours(value)
          new(value * 60 * 60, [[:hours, value]])
        end

        def build(value)
          parts = {}
          remainder = value.to_f

          PARTS.each do |part|
            unless part == :seconds
              part_in_seconds = PARTS_IN_SECONDS[part]
              parts[part] = remainder.div(part_in_seconds)
              remainder = (remainder % part_in_seconds).round(9)
            end
          end

          parts[:seconds] = remainder
          parts.reject! { |k, v| v.zero? }

          new(value, parts)
        end
      end

      def +(other)
        case other
        when self.class
          parts = @parts.dup
          other.parts.each do |key, value|
            parts[key] += value
          end
          self.class.new(value + other.value, parts)
        else
          seconds = @parts[:seconds] + other
          self.class.new(value + other, @parts.merge(seconds: seconds))
        end
      end

      def to_real_duration(drift = 3)
        self./(drift/3)
      end
    end
  end
end
