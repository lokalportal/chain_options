# frozen_string_literal: true

module ChainOptions
  #
  # This class represents an Option from a ChainOptions::OptionSet and is
  # mainly responsible for handling option state.
  #
  class Option
    # The Parameters that need to be turned into instance methods, if they are symbols.
    METHOD_SYMBOLS = %i[filter validate].freeze
    PARAMETERS     = %i[incremental default transform filter validate invalid allow_block].freeze

    (PARAMETERS - [:allow_block]).each do |param|
      define_method(param) { options[param] }
      private param
    end

    def allow_block
      options[:allow_block]
    end

    #
    # Extracts options and sets all the parameters.
    #
    def initialize(options)
      self.options = options
      @dirty = false
    end

    #
    # Builds a new value for the option.
    # It automatically applies transformations and filters and validates the
    # resulting value, raising an exception if the value is not valid.
    #
    def new_value(*args, &block)
      value = value_from_args(args, &block)

      value = if incremental
                incremental_value(value)
              else
                filter_value(transformed_value(value))
              end

      if value_valid?(value)
        self.custom_value = value
      elsif invalid.to_s == 'default' && !incremental
        default_value
      else
        fail ArgumentError, "The value #{value.inspect} is not valid."
      end
    end

    #
    # The current value if there is one. Otherwise returns the default value.
    #
    def current_value
      return custom_value if dirty?

      default_value
    end

    #
    # Circumvents the normal value process to set an initial_value. Only works on a
    #   clean option.
    #
    def initial_value(value)
      raise ArgumentError, "The initial_value was already set to #{custom_value.inspect}." if dirty?

      self.custom_value = value
    end

    #
    # Looks through the parameters and returns the non-nil values as a hash
    #
    def to_h
      PARAMETERS.each_with_object({}) do |param, hash|
        next if send(param).nil?

        hash[param] = send(param)
      end
    end

    private

    attr_accessor :options

    # A value that has been set by a user. Overrides default_value.
    attr_reader :custom_value

    #
    # Sets the current value and marks the option as dirty.
    #
    def custom_value=(value)
      @dirty = true
      @custom_value = value
    end

    #
    # Returns the block if nothing else if given and blocks are allowed to be
    #   values.
    #
    def value_from_args(args, &block)
      return block if ChainOptions::Util.blank?(args) && block && allow_block

      flat_value(args)
    end

    #
    # Reverses the auto-cast to Array that is applied at `new_value`.
    #
    def flat_value(args)
      return args.first if args.is_a?(Enumerable) && args.count == 1

      args
    end

    #
    # Incremental values assume 2d arrays. Here the current_value is only
    #   prepended if the option is dirty.
    #
    def incremental_value(value)
      dirty? ? [*current_value, Array(value)] : [Array(value)]
    end

    #
    # Describes whether the default value has already been replaced.
    #
    def dirty?
      !!@dirty
    end

    #
    # Checks whether a new chain option value is valid or not using the `validate` values
    # used when setting up `chain_option`s.
    #
    # Please note that the value passed to this function already went through
    # the chain option's filters - if any. This means that it will always be a collection
    # if a filter was defined.
    #
    # If no validation was set up, the new value will always be accepted
    #
    # @return [Boolean] +true+ if the new value is valid.
    #
    def value_valid?(value)
      return true unless validate

      validate.call(value)
    end

    #
    # Applies a transformation to the given value.
    #
    # @param [Object] value
    #   The new value to be transformed
    #
    # If a `transform` was set up for the given option, it is used
    # as `to_proc` target when iterating over the value.
    # The value is always treated as a collection during this phase.
    #
    def transformed_value(value)
      return value unless transform

      transformed = Array(value).map(&transform)
      value.is_a?(Enumerable) ? transformed : transformed.first
    end

    #
    # Applies a filter to the given value.
    # Expects the value to be some kind of collection. If it isn't, it is treated
    # as an array with one element.
    #
    # @param [Object] value
    #   The new value to be filtered
    #
    # @example using a filter proc
    #   filter_value [1, 2, 3, 4, 5] # with filter: ->(entry) { entry.even? }
    #   #=> [2, 4]
    #
    def filter_value(value)
      return value unless filter

      Array(value).select(&filter)
    end

    #
    # @return [Object] the default value which was set for the given option name.
    #   If a proc is given, the result of `proc.call` will be returned.
    #
    def default_value
      return default unless default.respond_to?(:call)

      default.call
    end
  end
end
