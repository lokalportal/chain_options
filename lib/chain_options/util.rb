# frozen_string_literal: true

module ChainOptions
  module Util

    def self.blank?(obj)
      (obj.is_a?(Enumerable) && obj.empty?) || obj.nil? || obj == ''
    end

    def self.slice(hash, keys)
      keys.each_with_object({}) do |key, h|
        h[key] = hash[key] if hash[key]
      end
    end

    #
    # Evaluate the given proc in the context of the given object if the
    # block's arity is non-positive, or by passing the given object as an
    # argument if it is negative.
    #
    # ==== Parameters
    #
    # object<Object>:: Object to pass to the proc
    #
    def self.instance_eval_or_call(object, &block)
      if block.arity.positive?
        block.call(object)
      else
        ContextBoundDelegate.instance_eval_with_context(object, &block)
      end
    end

    #
    # Shamelessly copied from sunspot/sunspot with some alterations
    #
    class ContextBoundDelegate
      class << self
        def instance_eval_with_context(receiver, &block)
          calling_context = eval('self', block.binding, __FILE__, __LINE__)

          parent_calling_context = calling_context.instance_eval do
            @__calling_context__ if defined?(@__calling_context__)
          end

          calling_context = parent_calling_context if parent_calling_context
          new(receiver, calling_context).instance_eval(&block)
        end

        private :new
      end

      BASIC_METHODS = Set[:==, :equal?, :"!", :"!=", :instance_eval,
                          :object_id, :__send__, :__id__]

      instance_methods.each do |method|
        unless BASIC_METHODS.include?(method.to_sym)
          undef_method(method)
        end
      end

      def initialize(receiver, calling_context)
        @__receiver__, @__calling_context__ = receiver, calling_context
      end

      def id
        @__calling_context__.__send__(:id)
      rescue ::NoMethodError => e
        begin
          @__receiver__.__send__(:id)
        rescue ::NoMethodError
          raise(e)
        end
      end

      # Special case due to `Kernel#sub`'s existence
      def sub(*args, &block)
        __proxy_method__(:sub, *args, &block)
      end

      def method_missing(method, *args, &block)
        __proxy_method__(method, *args, &block)
      end

      def respond_to_missing?(meth)
        @__receiver__.respond_to?(meth) || @__calling_context__.respond_to?(meth)
      end

      def __proxy_method__(method, *args, &block)
        @__receiver__.__send__(method.to_sym, *args, &block)
      rescue ::NoMethodError => e
        begin
          @__calling_context__.__send__(method.to_sym, *args, &block)
        rescue ::NoMethodError
          raise(e)
        end
      end
    end
  end
end
