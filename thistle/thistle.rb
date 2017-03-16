require 'table_print'
module ATITD
  module Thistle
    class << self
      def vitamins
        %i(asc bio car fol nia pyr thi)
      end

      def inputs
        %i(nit pot h2o oxy sun)
      end

      def resources
        inputs + vitamins
      end
    end
  end
end

module ATITD::Thistle
  class Conversion < Module
    attr_reader :transform, :condition, :key

    module Voidlist
      def self.fetch(for_week:)
        require 'nokogiri'
        require 'open-uri'

        html = Nokogiri::HTML(open('http://www.atitd.org/wiki/tale6/Guilds/Twisted_Thistle/Voidlist'))

        map = html.css('table tr').
          map { |row| row.css('td').map(&:text).map(&:strip) }.
          reject { |row| row.first.to_i.zero? }.
          map { |row| [ row.first.to_i, row.last ] }.
          to_h

        voids = map[for_week]
        if !voids.nil? && !voids.empty?
          voids.split($/).map { |line| line.gsub(/[\s\d\.]+/, '') }
        end
      end
    end

    class Transform
      attr_reader :input_amt, :output_amt
      attr_reader :input_res, :output_res
      alias :input :input_res
      def initialize(text)
        @input_amt, @input_res, @output_amt, @output_res =
          text.strip.match(/(\d+)\s*(\w+)\s*(?:->|→)\s*([\.\d]+)\s*(\w+)/).to_a[1..-1]
        @input_amt = @input_amt.to_i
        @output_amt = @output_amt.to_f
        @input_res = @input_res.downcase.to_sym
        @output_res = @output_res.downcase.to_sym
      end

      def apply(state)
        state.dup.tap do |hash|
          used_res = [ hash[@input_res], @input_amt ].min
          hash[@output_res] += used_res * (@output_amt/@input_amt)
          hash[@input_res] -= used_res

          hash[@output_res] = 99 if hash[@output_res] > 99
          hash[@input_res] = 0 if hash[@input_res] < 0
        end
      end

      def to_key
        [ input_res, output_res ].map(&:capitalize).join('->')
      end
    end

    class Condition
      attr_reader :resource, :operation, :amount
      def initialize(text)
        @resource, @operation, @amount = text.strip.match(/(\w+)\s*([<>])\s*(\d+)/).to_a[1..-1]
        @resource = @resource.downcase.to_sym
        @operation = @operation.to_sym
        @amount = @amount.to_i
      end

      def applies?(state)
        state[resource].send(operation, amount)
      end
    end

    def self.list
      @list ||= [
        new(condition: 'H2O > 79', transform: '10 Nit → 3.33 Asc'),
        new(condition: 'Oxy < 49', transform: '10 Car → 5 Asc'),
        new(condition: 'Sun > 69', transform: '10 Fol → 20 Asc'),
        new(condition: 'Sun < 20', transform: '10 Pot → 2.5 Bio'),
        new(condition: 'H2O < 29', transform: '10 Asc → 20 Bio'),
        new(condition: 'Oxy > 89', transform: '10 Pyr → 10 Bio'),
        new(condition: 'Oxy > 69', transform: '10 Pot → 3.33 Car'),
        new(condition: 'Sun > 79', transform: '10 Asc → 10 Car'),
        new(condition: 'H2O < 39', transform: '10 Thi → 20 Car'),
        new(condition: 'Sun > 69', transform: '10 Pot → 2.5 Fol'),
        new(condition: 'H2O < 59', transform: '10 Nia → 30 Fol'),
        new(condition: 'Oxy < 49', transform: '10 Thi → 20 Fol'),
        new(condition: 'Sun < 20', transform: '10 Asc → 20 Nia'),
        new(condition: 'H2O > 69', transform: '10 Pyr → 5 Nia'),
        new(condition: 'Oxy < 39', transform: '10 Thi → 10 Nia'),
        new(condition: 'H2O < 39', transform: '10 Nit → 3.33 Pyr'),
        new(condition: 'Sun > 59', transform: '10 Car → 10 Pyr'),
        new(condition: 'Oxy > 79', transform: '10 Fol → 20 Pyr'),
        new(condition: 'Sun < 40', transform: '10 Asc → 10 Thi'),
        new(condition: 'Oxy < 49', transform: '10 Car → 20 Thi'),
        new(condition: 'H2O < 49', transform: '10 Nia → 5 Thi'),
      ]
    end

    def self.void!(*conversions)
      conversions.each do |void|
        list.find { |c| c.transform.to_key == void }.void!
      end
    end

    def self.reset_voids!
      list.each { |c| c.void!(false) }
    end

    def self.voids=(conversions)
      list.select { |c| c.void!(conversions.include?(c.transform.to_key)) }
    end

    def self.voids_from_paste!
      voids = `pbpaste`.split($/).map { |line| line.gsub(/[\s\d\.]+/, '') }
    end

    def initialize(transform:, condition:)
      @condition = Condition.new(condition)
      @transform = Transform.new(transform)
      @key = @transform.to_key
    end

    def applies?(state)
      @condition.applies?(state)
    end

    def void!(bool = true); @void = bool; end
    def void?; @void; end

    def inspect
      transform.to_key
    end
  end

  class Recipe
    def self.from(conversions:, text:)
      Conversion.voids = conversions
      from_text(text)
    end

    def self.from_text(text)
      instr_to_inputs = lambda do |text|
        text.split(':').last.scan(/\w\d+/).map do |input|
          [ case input[0]
              when 'n' then :nit
              when 'p' then :pot
              when 'w' then :h2o
              when 'o' then :oxy
              when 's' then :sun
            end,
            input[1..-1].to_i
          ]
        end.to_h
      end
      instructions = text.split(' ')
      cursor = 0
      Run.new(**instr_to_inputs.call(instructions.shift)).tap do |run|
        instructions.each do |step|
          parts = step.split(':')
          tick = parts[0][1..-1].to_i
          inputs = instr_to_inputs.call(parts[1])
          run.step(tick - cursor)
          cursor += tick - cursor
          run.input(inputs)
        end
        run.step(40 - cursor)
      end
    end

    def self.from_run(run)
      run.ticks.map do |tick|
        next if tick.inputs.empty?
        "t#{tick.index}:#{tick.inputs.to_recipe}"
      end.compact.join(' ')
    end
  end

  class State < Hash
    def self.[](*args)
      super.tap { |hash| hash.default = 0 }
    end

    ATITD::Thistle.resources.each do |res|
      define_method(res) do
        self[res]
      end
    end

    def with(inputs)
      dup.tap do |hash|
        inputs.each do |resource, count|
          case resource
            when :nit, :pot, :h2o, :oxy
              count.times { hash[resource] += 20 }
              hash[resource] = 99 if hash[resource] > 99
            when :sun
              hash[resource] = count
          end
        end
      end
    end

    def exists?(vitamin)
      self[vitamin] > 0
    end

    def decrement_resources
      dup.tap do |hash|
        %i(nit pot h2o oxy).each do |res|
          hash[res] -= 10
          hash[res] = 0 if hash[res] < 0
        end
      end
    end
  end

  class Inputs < Hash
    def initialize
      self.default = 0
    end

    def to_recipe
      map do |k, v|
        case k
        when :h2o then 'w'
        else k.to_s[0]
        end + v.to_s
      end.join
    end
  end

  class Run
    class Tick
      def initialize(index, state, inputs)
        @index = index
        @inputs = Inputs.new.merge(inputs)
        @conversions = []
        @state = state
      end
      attr_reader :index, :inputs

      def input(**options)
        @inputs.merge!(options)
        determine_conversions!
      end

      def determine_conversions!
        @conversions.clear
        available_conversions = Conversion.list.reject { |c| c.void? }
        available_conversions.reduce(@state.with(@inputs)) do |memo, c|
          if c.applies?(memo)
            @conversions << c if memo.decrement_resources.exists?(c.transform.input)
            c.transform.apply(memo)
          else
            memo
          end
        end
      end

      def next
        determine_conversions!
        Tick.new(@index.succ, @conversions.reduce(@state.with(@inputs)) do |state, c|
          c.transform.apply(state)
        end.decrement_resources, {})
      end

      def vitamins
        ATITD::Thistle.vitamins.map do |res|
          res.to_s[0].capitalize + case @state[res]
            when 0..20 then '-'
            when 21..80 then '~'
            when 81..99 then '+'
            else '!'
          end
        end.join
      end

      def to_tp
        @state.
          with(@inputs).
          merge(tick: index,
                inputs: @inputs.to_recipe,
                conversions: @conversions.map(&:inspect).join(', '),
                vitamins: vitamins)
      end
    end

    def initialize(**options)
      @ticks = [ Tick.new(0, State[nit: 50, pot: 50, h2o: 50, oxy: 50, sun: 99], options) ]
    end

    def step(num = 1)
      num.times { @ticks << @ticks.last.next }
      self
    end
    attr_reader :ticks

    def input(**options)
      @ticks.last.input(**options)
      self
    end

    def print_headers
      [ :tick,
        :inputs,
        ATITD::Thistle.inputs.map { |res| { res => lambda { |u| u.send(res).to_i } } },
        { :"---" => lambda { |u| ' ' } },
        ATITD::Thistle.vitamins.map { |res| { res => lambda { |u| u.send(res).round } } },
        :conversions,
        :vitamins
      ].flatten
    end

    def print
      puts "Current Voids: #{ATITD::Thistle::Conversion.list.select(&:void?).map(&:inspect).join(', ')}"
      puts "Recipe: #{to_recipe}"
      puts "Result: #{ticks.last.vitamins}"
      puts

      tp.set :max_width, 150
      tp ticks.map(&:to_tp), *print_headers
    end

    def to_recipe
      Recipe.from_run(self)
    end
  end
end

# End of Tick -> Inputs -> Conversions -> Start of Tick
