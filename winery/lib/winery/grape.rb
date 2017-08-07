require 'json'

class Hash
  def slice(*keys)
    keys.map! { |key| convert_key(key) } if respond_to?(:convert_key, true)
    keys.each_with_object(self.class.new) { |k, hash| hash[k] = self[k] if has_key?(k) }
  end
end

module ATITD
  class Winery
    class Grape < Hash
      CODES = {
        'Aerate the soil' => 'as',
        'Mist the grapes' => 'mg',
        'Pinch off the weakest stems' => 'po',
        'Shade the leaves' => 'sl',
        'Spread out the vines' => 'sv',
        'Tie the vines to the trellis' => 'tv',
        'Trim the lower leaves' => 'tl'
      }

      def self.from_json(json)
        self[::JSON.parse(json)]
      end

      def self.from_file(file)
        (@files ||= {})[file] =
          from_json(File.read(
            File.expand_path(File.join(__FILE__, "../grape/#{file}.json"))
          ))
      end

      def inspect
        "#<#{self.class}:#{'0x%x' % (object_id << 1)} #{self['name']}>"
      end

      def best_with_strategy(strategy)
        self.slice(CODES.values).map do |state, options|
          [ state, CODES.invert[options.max_by(&strategy).first] ]
        end.compact.to_h
      end
    end
  end
end
