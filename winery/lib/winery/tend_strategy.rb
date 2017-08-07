module ATITD
  class Winery
    class TendStrategy
      STRATEGIES = {
        sugar: { proc: lambda { |_, change| change['s'] }, name: 'Max Sugar' },
        color_skin: {
          proc: lambda { |_, change| change['k'] * change['c'] },
          name: 'Max Color*Skin'
        },
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
  end
end
