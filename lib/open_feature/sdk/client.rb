# frozen_string_literal: true

require_relative "hooks"

module OpenFeature
  module SDK
    # TODO: Write documentation
    #
    class Client
      include OpenFeature::SDK::Hooks::Hookable

      RESULT_TYPE = %i[boolean string number object].freeze
      SUFFIXES = %i[value details].freeze

      attr_reader :metadata, :evaluation_context

      def initialize(provider:, domain: nil, evaluation_context: nil)
        @provider = provider
        @metadata = ClientMetadata.new(domain:)
        @evaluation_context = evaluation_context
      end

      RESULT_TYPE.each do |result_type|
        SUFFIXES.each do |suffix|
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            # def fetch_boolean_details(flag_key:, default_value:, evaluation_context: nil)
            #   result = @provider.fetch_boolean_value(flag_key: flag_key, default_value: default_value, evaluation_context: evaluation_context)
            # end
            def fetch_#{result_type}_#{suffix}(flag_key:, default_value:, evaluation_context: nil)
              built_context = EvaluationContextBuilder.new.call(api_context: OpenFeature::SDK.evaluation_context, client_context: self.evaluation_context, invocation_context: evaluation_context)
              hook_context = Hooks::Context.new(flag_key: flag_key, flag_type: :#{result_type}, default_value: default_value, evaluation_context: built_context, provider_metadata: @provider.metadata, client_metadata: @metadata)
              begin
                run_before_hooks(hook_context, nil)
                resolution_details = @provider.fetch_#{result_type}_value(flag_key:, default_value:, evaluation_context: built_context)
                run_after_hooks(hook_context, resolution_details, nil)
                evaluation_details = EvaluationDetails.new(flag_key:, resolution_details:)
                #{"evaluation_details.value" if suffix == :value}
              rescue => e
                run_error_hooks(hook_context, e, nil) 
              ensure
                run_finally_hooks(hook_context, nil)
              end
            end
          RUBY
        end
      end

      private

      def run_error_hooks(hook_context, exception, hook_hints)
        error_hooks = OpenFeature::SDK.hooks[:error]
        error_hooks.each do |hook|
          hook.call(hook_context: hook_context, exception: exception, hook_hints: hook_hints)
        end
      end

      def run_before_hooks(hook_context, hook_hints)
        before_hooks = OpenFeature::SDK.hooks[:before]
        before_hooks.each do |hook|
          evaluation_context = hook.call(hook_context:, hook_hints:)
          if evaluation_context
            hook_context.evaluation_context = evaluation_context
          end
        end
      ensure
        hook_context.evaluation_context.freeze
      end

      def run_after_hooks(hook_context, flag_evaluation_details, hook_hints)
        after_hooks = OpenFeature::SDK.hooks[:after]
        after_hooks.each do |hook|
          hook.call(hook_context:, flag_evaluation_details:, hook_hints:)
        end
      end

      def run_finally_hooks(hook_context, hook_hints)
        finally_hooks = OpenFeature::SDK.hooks[:finally]
        finally_hooks.each do |hook|
          hook.call(hook_context:, hook_hints:)
        end
      end
    end
  end
end
