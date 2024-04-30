module OpenFeature
  module SDK
    module Hooks
      module Hook
        def before(hook_context:, hook_hints: nil)
        end

        def after(hook_context:, flag_evaluation_details:, hook_hints: nil)
        end

        def error(hook_context:, exception:, hook_hints: nil)
        end

        def finally(hook_context:, hook_hints: nil)
        end
      end
    end
  end
end
