require "delegate"

module OpenFeature
  module SDK
    module Hooks
      class Hints < SimpleDelegator
        ALLOWED_TYPES = [String, Symbol, Numeric, TrueClass, FalseClass, Time, Hash, Array].freeze

        def initialize(hints)
          unless hints.is_a?(Hash)
            raise ArgumentError, "Hints must be a Hash"
          end
          hints.each_key { |key| raise ArgumentError, "Only String or Symbol are allowed as keys" unless key.is_a?(String) || key.is_a?(Symbol) }
          hints.each_value do |v|
            raise ArgumentError, "Only #{ALLOWED_TYPES.join(", ")} are allowed as values. But #{v} is a #{v.class}" unless ALLOWED_TYPES.any? { |t| v.is_a?(t) }
          end
          super(hints)
          freeze
        end

        def freeze
          __getobj__.each do |k, v|
            k.freeze
            v.freeze
          end
          __getobj__.freeze
          super
        end
      end
    end
  end
end
