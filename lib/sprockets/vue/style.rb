require 'css_parser'

module Sprockets::Vue
  class Style
    class << self
      STYLE_REGEX = Utils.node_regex('style')
      STYLE_COMPILES = {
        'scss' => Sprockets::ScssProcessor,
        'sass' => Sprockets::SassProcessor,
        nil => ->(i){i[:data]}
      }

      def call(input)
        data = input[:data]
        input[:cache].fetch([cache_key, input[:filename], data]) do
          style = STYLE_REGEX.match(data)

          if style
            input[:data] = style[:content]

            built_css = STYLE_COMPILES[style[:lang]].call(input)

            if style[:scoped]
              parser = CssParser::Parser.new
              parser.load_string! built_css

              uniq_selector = Utils.scope_key(input[:filename])

              parser.each_rule_set do |rs|
                rs.selectors.each do |s|
                  s.sub!(/(\s|$)/, "[data-#{uniq_selector}] ")
                end
              end

              built_css = parser.to_s
            end

            built_css
          else
            ''
          end
        end
      end

      def cache_key
        [
          self.name,
          VERSION,
        ].freeze
      end
    end
  end
end
