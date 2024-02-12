require 'active_support/concern'
require "action_view"

module Sprockets::Vue
  class Script
    class << self
      include ActionView::Helpers::JavaScriptHelper

      SCRIPT_REGEX = Utils.node_regex('script')
      TEMPLATE_REGEX = Utils.node_regex('template')
      SCRIPT_COMPILES = {
        'coffee' => ->(s, input){
          CoffeeScript.compile(s, sourceMap: true, sourceFiles: [input[:source_path]], no_wrap: true)
        },
        'es6' => ->(s, input){
          opts = {
            'sourceRoot' => input[:load_path],
            'moduleRoot' => nil,
            'filename' => input[:filename],
            'filenameRelative' => input[:environment].split_subpath(input[:load_path], input[:filename])
          }

          result = Babel::Transpiler.transform(s, opts)

          { 'js' => result['code'] }
        },
        nil => ->(s,input){ { 'js' => s } }
      }

      TEMPLATE_COMPILES = {
        'slim' => ->(s) { Slim::Template.new { s }.render },
        'slm' => ->(s) { Slim::Template.new { s }.render },
        nil => ->(s) { s }
      }

      def call(input)
        data = input[:data]
        name = input[:name]

        input[:cache].fetch([cache_key, input[:source_path], data]) do
          script = SCRIPT_REGEX.match(data)
          template = TEMPLATE_REGEX.match(data)
          output = []
          map = nil

          if script
            result = SCRIPT_COMPILES[script[:lang]].call(script[:content], input)

            map = result['sourceMap']

            output << "'object' != typeof VComponents && (this.VComponents = {});
              var module = { exports: null };
              #{result['js']}; VComponents['#{name}'] = module.exports;"
          end

          if template
            built_template = TEMPLATE_COMPILES[template[:lang]].call(template[:content])

            output << "VComponents['#{name.sub(/\.tpl$/, "")}'].template = '#{j built_template}';"
          end

          { data: "#{wrap(output.join)}", map: map }
        end
      end

      def wrap(s)
        "(function(){#{s}}).call(this);"
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
