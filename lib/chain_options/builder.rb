# frozen_string_literal: true

module ChainOptions
  #
  # A simple helper class to set multiple chain options after another
  # by using a `set NAME, VALUE` syntax instead of having to
  # use constructs like
  #   instance = instance.NAME(VALUE)
  #   instance = instance.NAME2(VALUE2) if XY
  #   ...
  #
  class Builder
    def initialize(initial_instance, &block)
      @instance = initial_instance
      ChainOptions::Util.instance_eval_or_call(self, &block)
      result
    end

    def result
      @instance
    end

    def set(option_name, *value, &block)
      @instance = @instance.send(option_name, *value, &block)
    end
  end
end
