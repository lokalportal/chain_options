# frozen_string_literal: true

module ChainOptions
  class OptionSet

    class << self

      #
      # Warns of incompatible options for a chain_option.
      # This does not necessarily mean that an error will be raised.
      #
      def warn_incompatible_options(option_name, *options)
        STDERR.puts "The options #{options.join(', ')} are incompatible for the chain_option #{option_name}."
      end

      #
      # Prints warnings for incompatible options which were used as arguments in `chain_option`
      #
      def handle_warnings(name, incremental: false, invalid: :raise, filter: nil, transform: nil, **)
        if incremental
          warn_incompatible_options(name, 'invalid: :default', 'incremental: true') if invalid.to_s == 'default'
          warn_incompatible_options(name, 'incremental: true', 'filter:') if filter
          warn_incompatible_options(name, 'incremental: true', 'transform:') if transform
        end
      end
    end

    #
    # @param [Object] instance the object that uses the chain_option set.
    # @param [Hash] chain_options a hash of `{name: config_hash}` to initialize
    #   options from a config hash.
    # @param [Hash] values a hash of `{name: value}` with initial values for the
    #   named options.
    #
    def initialize(instance, chain_options = {}, values = {})
      @instance      = instance
      @values        = values
      @chain_options = chain_options.inject({}) do |options, (name, config)|
        options.merge(name => config.merge(instance_method_hash(config)))
      end
    end

    attr_reader :instance

    #
    # Checks the given option-parameters for incompatibilities and registers a
    #   new option.
    #
    def add_option(name, parameters)
      self.class.handle_warnings(name, **parameters.dup)
      chain_options.merge(name => parameters.merge(method_hash(parameters)))
    end

    #
    # Returns the current_value of an option.
    #
    def current_value(name)
      option(name).current_value
    end

    #
    # Returns an option registered under `name`.
    #
    def option(name)
      config = chain_options[name] || raise_no_option_error(name)
      Option.new(config).tap { |o| o.initial_value(values[name]) if values.key?(name) }
    end

    #
    # Builds a new value for the given chain option.
    # It automatically applies transformations and filters and validates the
    # resulting value, raising an exception if the value is not valid.
    #
    def new_value(name, *args, &block)
      option(name).new_value(*args, &block)
    end

    #
    # Handles a call of #option_name.
    # Determines whether the call was meant to be a setter or a getter and
    # acts accordingly.
    #
    def handle_option_call(option_name, *args, &block)
      if getter?(option_name, *args, &block)
        current_value(option_name)
      else
        new_value = new_value(option_name, *args, &block)
        instance.class.new(@values.merge(option_name.to_sym => new_value))
      end
    end

    private

    attr_reader :values, :chain_options

    #
    # @return [Boolean] +true+ if a call to the corresponding option method with the given args / block
    #   can be handled as a getter (no args / no block usage)
    #
    def getter?(option_name, *args, &block)
      args.empty? && (block.nil? || !option(option_name).allow_block)
    end

    # no-doc
    def raise_no_option_error(name)
      fail ArgumentError, "There is no option registered called #{name}."
    end

    #
    # Checks the given options and transforms certain options into closures,
    #   if they are symbols before.
    # The keys that are being transformed can be seen at `Option::METHOD_SYMBOLS`.
    # @return [Hash] a set of parameters and closures.
    #
    def instance_method_hash(options)
      ChainOptions::Util.slice(options, Option::METHOD_SYMBOLS).each_with_object({}) do |(meth, value), h|
        next h[meth] = value if value.respond_to?(:call)

        h[meth] = instance.public_method(value)
      end
    end
  end
end
