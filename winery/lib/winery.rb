require_relative 'winery/grape'
require_relative 'winery/tend_strategy'
require_relative 'winery/vineyard'
require_relative 'winery/vineyard/coding'

class Array
  def sum(&block)
    inject(0) do |sum, n|
      sum + block.call(n)
    end
  end

  def average(&block)
    sum(&block).to_f / size
  end
  alias avg average
end

module ATITD
  class Winery
    def initialize(vineyards)
      @vineyards = vineyards.map do |vineyard|
        case vineyard
          when String then Vineyard.decode(vineyard)
          when Vineyard then vineyard
        end
      end
    end
    attr_reader :vineyards

    def combinations(grape_strategies)
      (0...grape_strategies.size**@vineyards.size).map do |number|
        number.
          to_s(grape_strategies.size).
          rjust(@vineyards.size, '0').
          split('').
          map.with_index do |gs_index, v_index|
            [ @vineyards[v_index], grape_strategies[gs_index.to_i] ]
          end.to_h
      end.
        map(&Plan.method(:new))
    end

    class Plan
      def initialize(blueprint)
        @vineyards = (@blueprint = blueprint).map do |vineyard, grape_strategy|
          vineyard.with(grape_strategy)
        end
      end

      def inspect
        @blueprint.each do |vineyard, grape_strategy|
          puts " #{vineyard.inspect} | #{grape_strategy.inspect}"
        end
      end

      def run
        @run ||= @vineyards.map(&:run)
      end

      def result
        @result ||= @vineyards.map(&:result)
      end

      def bottles
        result.sum { |vineyard| vineyard[:g] } / 21
      end
      
      def tannin
        result.avg { |vineyard| vineyard[:k] * vineyard[:c] }
      end
    end
  end
end
