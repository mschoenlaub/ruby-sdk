# frozen_string_literal: true

module OpenFeature
  module SDK
    module Hooks
      class Context
        attr_reader :flag_key, :flag_type, :default_value, :provider_metadata, :client_metadata
        attr_accessor :evaluation_context

        def initialize(flag_key:, flag_type:, default_value:, evaluation_context:, provider_metadata: nil, client_metadata: nil)
          @flag_key = flag_key.freeze
          @flag_type = flag_type.freeze
          @default_value = default_value.freeze
          @evaluation_context = evaluation_context
          @provider_metadata = provider_metadata.freeze
          @client_metadata = client_metadata.freeze
        end
      end
    end
  end
end
