require 'json'

class Array
  def explode_by_combination(join_with = '.')
    parts = map { |part| part.respond_to?(:to_a) ? part.to_a.map(&:to_s) : [ part.to_s ] }
    combinations = parts.shift.map { |part| [ part ] }
    parts.inject(combinations) do |combos, part_values|
      combos.map { |combo| part_values.map { |part| combo + [ part ] } }.flatten(1)
    end.map do |combo|
      combo.join(join_with)
    end
  end
end

module ATITD
  module Vineyard
    class BruteForceSolver
      class TendTable < Hash
        CODES = {
          'Aerate the soil' => 'as',
          'Mist the grapes' => 'mg',
          'Pinch off the weakest stems' => 'po',
          'Shade the leaves' => 'sl',
          'Spread out the vines' => 'sv',
          'Tie the vines to the trellis' => 'tv',
          'Trim the lower leaves' => 'tl'
        }
      end

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

        def to_s
          coded
        end
      end

      class Solution
        attr_writer :vineyard, :actions, :tend_table
        attr_reader :solution

        def self.generate_actions_for(vineyard_size)
          Array.new(vineyard_size).
            map { TendTable::CODES.values }.
            explode_by_combination.
            map { |actions| Solution.new.tap do |solution|
              solution.actions = actions.split('.')
            end }
        end

        def initial_state
          { a: 0, c: 0, g: nil, q: 0, k: 0, s: 0, v: 100 }
        end

        def construct!
          @solution = @vineyard.each_with_object(
            initial_state.merge(g: @tend_table['starting'])
          ) do |state, memo|
            @tend_table[state][@actions.shift].each do |change, amount|
              memo[change.to_sym] += amount
            end
          end
        end
      end

      class Strategy
        STRATEGIES = {
          sugar: { proc: lambda { |_, change| change['s'] }, name: 'Max Sugar' },
          color_skin: { proc: lambda { |_, change| change['k'] * change['c'] }, name: 'Max Color*Skin' },
          vigor: { proc: lambda { |_, change| change['v'] }, name: 'Min Vigor' },
          grapes: { proc: lambda { |_, change| change['g'] }, name: 'Max Grapes' },
        }

        def initialize(code)
          @code = code
        end

        def name
          STRATEGIES.fetch(@code.to_sym)[:name]
        end

        def to_proc
          STRATEGIES.fetch(@code.to_sym)[:proc]
        end
      end

      class TendStrategy
        def initialize(tend_table:, strategy:)
          @table = TendTable[JSON.parse(File.read(
            File.expand_path(File.join(__FILE__, "../../docs/#{tend_table}.json"))
          ))]
          @strategy = Strategy.new(strategy)
        end

        def solution
          @table.map do |state, options|
            next unless options.is_a? Hash
            [ state, TendTable::CODES.invert[options.max_by(&@strategy).first] ]
          end.compact.to_h
        end
      end

      def initialize(vineyard:, tend_table:, strategy:)
        @table = TendTable[JSON.parse(File.read(
          File.expand_path(File.join(__FILE__, "../../docs/#{tend_table}.json"))
        ))]
        @vineyard = Vineyard.decode(vineyard)
        @strategy = Strategy.new(strategy)
      end

      def run
        initial_state = { a: 0, c: 0, g: nil, q: 0, k: 0, s: 0, v: 100 }
        require 'table_print'
        run = []
        puts "Vineyard: #{@vineyard}"
        puts "Grape: #{@table['name']}"
        puts "Strategy: #{@strategy.name}"
        puts

        @result = @vineyard.each_with_object(
          initial_state.merge(g: @table['starting'])
        ) do |state, memo|
          tick = {}
          tick[:vineyard] = state
          @table[state].
            max_by(&@strategy).
            tap { |(action, _)| tick[:tend] = TendTable::CODES.invert[action] }.
            last.
            tap do |tend_action|
            break if memo[:v] - tend_action['v'] <= 0
            tend_action.each do |(change, amount)|
              memo[change.to_sym] += amount
              memo[change.to_sym] = [0, memo[change.to_sym]].max
            end
            end
          run << tick.merge(memo) if memo[:v] > 0
        end
        tp run
      end
      attr_reader :result

      def solutions
        @solutions ||= Solution.
          generate_actions_for(@vineyard.size).
            each.with_index do |solution, index|
              puts "##{index.succ}. #{Time.now}"
              solution.vineyard = @vineyard
              solution.tend_table = @table
              solution.construct!
        end
      end
    end
  end
end

ATITD::Vineyard::BruteForceSolver.new(tend_table: ARGV[0], vineyard: ARGV[1], strategy: ARGV[2]).send(ARGV[3] || :run) if __FILE__ == $0
