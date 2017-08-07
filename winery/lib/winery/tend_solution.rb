module ATITD
  class Winery
    module TendSolution
      def self.for(grape_strategies)
        require 'table_print'
        Grape::CODES.values.map do |vineyard_state|
          { vineyard: vineyard_state }
        end
      end
    end
  end
end
