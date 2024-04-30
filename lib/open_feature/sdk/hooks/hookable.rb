module OpenFeature
  module SDK
    module Hooks
      module Hookable
        HOOK_TYPES = %i[before after error finally].freeze

        def add_hook(hook_type, hook = nil, &block)
          unless hooks.key?(hook_type)
            raise ArgumentError, "Hook type must be one of #{hooks.keys.join(", ")}"
          end
          if hook && block
            raise ArgumentError, "Cannot provide both a hook and a block"
          end
          hook ||= block
          unless hook
            raise ArgumentError, "Must provide either a hook or a block"
          end
          hooks[hook_type] << to_procish(hook_type, hook)
        end

        def add_hooks(*hooks)
          is_valid_hook = false
          hooks.each do |hook|
            [:before, :after, :error, :finally].each do |hook_type|
              if hook.respond_to?(hook_type)
                is_valid_hook = true
                self[hook_type] << hook.method(hook_type)
              end
            end
          end
          unless is_valid_hook
            raise ArgumentError, "Hook must respond to one of :before, :after, :error, or :finally"
          end
        end

        def hooks
          @hooks ||= {
            before: [],
            after: [],
            error: [],
            finally: []
          }
        end

        private

        def to_procish(hook_type, hook)
          if hook.respond_to?(hook_type)
            hook.method(hook_type)
          elsif hook.respond_to?(:call)
            hook
          else
            raise ArgumentError, "Hook must respond to #{hook_type} or :call"
          end
        end
      end
    end
  end
end
