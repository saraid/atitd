module ATITD
  module Vineyard
    class Coding
      MAPPING = {
        G: /sag/i,
        W: /wilt/i,
        M: /musty/i,
        F: /fat/i,
        R: /rustl/i,
        V: /shrivel/i,
        H: /shimmer/i
      }

      def initialize(string)
        @errors = []
        puts(string.split($/).map.with_index do |line, index|
          case line
          when /sag/i then :G
          when /wilt/i then :W
          when /musty/i then :M
          when /fat/i then :F
          when /rustl/i then :R
          when /shrivel/i then :V
          when /shimmer/i then :H
          else
            @errors << { line: line, index: index }
            nil
          end
        end.compact.join(''))
        @errors.each do |error|
          puts "#{index.succ}. #{line}"
        end
      end
    end
  end
end

ATITD::Vineyard::Coding.new($stdin.read) if __FILE__ == $0
