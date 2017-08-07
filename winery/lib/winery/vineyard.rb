module ATITD
  class Winery
    class Vineyard < Array

      CODES = {
        G: 'sagging',
        W: 'wilting',
        M: 'musty',
        F: 'fat',
        R: 'rustle',
        V: 'shrivel',
        H: 'shimmer'
      }
      attr_accessor :coded

      def self.decode(string)
        new(string.split('').map { |x| CODES[x.to_sym] }).tap do |vineyard|
          vineyard.coded = string
        end
      end

      def inspect
        "#<#{self.class}:#{'0x%x' % (object_id << 1)} #{coded}>"
      end

      def to_s
        coded
      end

      def with_grape(grape)
        Instance.new(self).tap { |v| v.grape = grape }
      end

      def with_strategy(strategy)
        Instance.new(self).tap { |v| v.strategy = strategy }
      end

      def with(**grape_strategy)
        Instance.new(self).with(**grape_strategy)
      end

      class Instance
        def initialize(vineyard)
          @vineyard = vineyard
        end

        def grape=(grape)
          @grape = grape
          self
        end

        def strategy=(strategy)
          @strategy = strategy
          self
        end
        alias :with_grape :grape=
        alias :with_strategy :strategy=

        def with(grape:, strategy:)
          self.grape = grape
          self.strategy = strategy
          self
        end

        def initial_state
          { a: 0, c: 0, g: nil, q: 0, k: 0, s: 0, v: 100 }
        end

        def result
          @result ||= run.last.slice(*initial_state.keys)
        end

        def run
          @run = []
          @vineyard.each_with_object(
            initial_state.merge(g: @grape['starting'])
          ) do |state, memo|
            tick = { vineyard: state }
            @grape[state].
              max_by(&@strategy).
              tap { |(action, _)| tick[:tend] = Grape::CODES.invert[action] }.
              last.
              tap do |tend_action|
                break if memo[:v] - tend_action['v'] <= 0
                tend_action.each do |(change, amount)|
                  memo[change.to_sym] += amount
                  memo[change.to_sym] = [0, memo[change.to_sym]].max
                end
              end
            @run << tick.merge(memo) if memo[:v] > 0
          end
          @run
        end
      end
    end
  end
end
