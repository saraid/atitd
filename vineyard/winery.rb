require_relative './bruteforce'

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
    GRAPES = { tend_table: :tedra388, strategy: :grapes }
    TANNIN = { tend_table: :pascalito356, strategy: :color_skin }

    VINEYARDS = {
      'VMMRWRGRMGRFGWFGWVHW'  => GRAPES,
      'VVVFRWWRVGFVHMHRVW'    => GRAPES,
      'GFGWFHHRMHFFVVMH'      => TANNIN,
      'HWMGWHMMMHHGGMRW'      => GRAPES,
      'GRFWMFRRFMFFWFFV'      => TANNIN,
      'FWHGVFGRHWHVVG'        => TANNIN,
      'VVWWRGWRFWGMHFF'       => GRAPES,
      'RRRGGFGGFMVHHF'        => TANNIN
    }

    def self.combinations
      (0..255).map do |number|
        binary_representation = number.to_s(2).rjust(8, '0')
        binary_representation.split('').map.with_index do |x, i|
          [ VINEYARDS.keys[i], x == '0' ? GRAPES : TANNIN ]
        end.to_h
      end.
        map(&method(:new))
    end

    def self.best_tannin(with_bottles = 30)
      combinations.
        map(&:run).
        select { |result| result[:bottles] == with_bottles }.
        max_by { |result| result[:tannin] }
    end

    def initialize(decision)
      @decision = decision
    end

    def run(decision)
      vineyards = decision.map do |vineyard, choice|
        puts
        ATITD::Vineyard::BruteForceSolver.
          new(tend_table: choice[:tend_table],
              vineyard: vineyard,
              strategy: choice[:strategy]).
          tap { |yard| yard.run }
      end

      grapes = vineyards.sum { |yard| yard.result[:g] }
      color  = vineyards.avg { |yard| yard.result[:c] }
      skin   = vineyards.avg { |yard| yard.result[:k] }

      puts
      puts "Total Grapes: #{grapes}"
      puts "Total Bottles: #{grapes / 21}"
      puts
      puts "Color * Skin: #{color * skin}"

      { bottles: grapes / 21, tannin: color * skin, decision: decision }
    end
  end
end

{ "VMMRWRGRMGRFGWFGWVHW"=>{:tend_table=>:tedra388, :strategy=>:grapes},
  "VVVFRWWRVGFVHMHRVW"=>{:tend_table=>:tedra388, :strategy=>:grapes},
  "GFGWFHHRMHFFVVMH"=>{:tend_table=>:tedra388, :strategy=>:grapes},
  "HWMGWHMMMHHGGMRW"=>{:tend_table=>:pascalito356, :strategy=>:color_skin},
  "GRFWMFRRFMFFWFFV"=>{:tend_table=>:pascalito356, :strategy=>:color_skin},
  "FWHGVFGRHWHVVG"=>{:tend_table=>:tedra388, :strategy=>:grapes},
  "VVWWRGWRFWGMHFF"=>{:tend_table=>:pascalito356, :strategy=>:color_skin},
  "RRRGGFGGFMVHHF"=>{:tend_table=>:pascalito356, :strategy=>:color_skin}}
}
