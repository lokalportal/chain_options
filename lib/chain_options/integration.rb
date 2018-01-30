# frozen_string_literal: true

module ChainOptions
  module Integration

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      #
      # Generates a combined getter and setter method for the
      # option with the given name.
      #
      # @param [String, Symbol] name
      #
      # @param [Hash] options
      # @option options [Object] :default (nil)
      #   Sets the value which should be used whenever no custom value was set for this option
      #
      # @option options [Symbol] :invalid (:raise)
      #   Sets the behaviour when an invalid value is given.
      #   If set to `:raise`, an ArgumentError is raised if an option validation fails,
      #   if set to `:default`, the default value is used instead of the invalid value
      #
      # @option options [Proc, Symbol, NilClass] :filter (nil)
      #   An optional filter method to reject certain values.
      #   See ChainOptions::OptionSet#filter_value for more information
      #
      # @option options [Proc, Symbol, NilClass] :transform (nil)
      #   An optional transformation that transforms the given value.
      #   See ChainOptions::OptionSet#transform_value for more information.
      #
      # @option options [Boolean] :allow_block (false)
      #   Sets whether the option value may be a proc object given through a block.
      #   If set to +true+, the following statement would result in `block` being saved as option value:
      #     instance.my_option(&block)
      #
      def chain_option(name, **options)
        available_chain_options[name.to_sym] = options

        ChainOptions::OptionSet.handle_warnings(name, **options)

        define_method(name) do |*args, &block|
          if args.empty? && (block.nil? || !chain_option_set.option(name).allow_block)
            chain_option_set.current_value(name)
          else
            new_value = chain_option_set.new_value(name, *args, &block)
            self.class.new(chain_option_values(name.to_sym => new_value))
          end
        end
      end

      def available_chain_options
        @available_chain_options ||= {}
      end
    end

    def initialize(**options)
      @chain_option_values = options
    end

    #
    # Allows setting multiple options in a block. This makes long option chains easier to read.
    #
    # @example The following expressions are equivalent
    #   instance.option1(value).option2(value).option3 { value3 }
    #   instance.build_options do
    #     set :option1, value
    #     set :option2, value2
    #     set(:option3) { value3 }
    #
    def build_options(&block)
      ChainOptions::Builder.new(self, &block).result
    end

    private

    def chain_option_set
      @chain_option_set ||= OptionSet.new(self, self.class.available_chain_options, chain_option_values)
    end

    #
    # @return [Hash] the currently set options for the current instance.
    #
    # @param [Hash] additional
    #   If given, the hash is merged with the existing option values for the result.
    #   This argument may be used to easily generate a new chain option hash with an additional
    #   value the next host instance can be initialized with.
    #
    def chain_option_values(**additional)
      (@chain_option_values ||= {}).merge(additional)
    end
  end
end
