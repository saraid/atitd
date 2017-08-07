module ATITD
  class Winery
    class Vineyard
      class Coding
        def initialize(string)
          @string = string
          @errors = []
        end

        def encode!
          puts(@string.split($/).map.with_index do |line, index|
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
            puts "#{error[:index].succ}. #{error[:line]}"
          end
        end

        def decode!
          @string.chomp.split('').map.with_index do |code, index|
            case code
            when 'G' then 'The vines are sagging a bit'
            when 'W' then 'Leaves are wilting'
            when 'M' then 'A musty smell can be detected'
            when 'F' then 'Stems look especially fat'
            when 'R' then 'Leaves rustle in the breeze'
            when 'V' then 'The grapes are starting to shrivel'
            when 'H' then 'Leaves shimmer with moisture'
            else
              @errors << { code: code, index: index }
              nil
            end
          end.compact.each(&Kernel.method(:puts))
          @errors.each do |error|
            puts "#{error[:index].succ}. #{error[:code].inspect}"
          end
        end
      end
    end
  end
end

if __FILE__ == $0
  ATITD::Vineyard::Coding.new($stdin.read).send(
    case ARGV.first
    when '--encode' then :encode!
    when '--decode' then :decode!
    else :encode!
    end
  )
end
