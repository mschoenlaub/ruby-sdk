require "spec_helper"

RSpec.describe "4. Hooks" do
  let(:noop_hook) do
    modified_evaluation_context = OpenFeature::SDK::EvaluationContext.new(before: "before")
    double("noop_hook", before: evaluation_context.merge(modified_evaluation_context), after: nil)
  end
  let(:evaluation_context) { OpenFeature::SDK::EvaluationContext.new }
  context "4.1 Context" do
    let(:evaluation_context) { OpenFeature::SDK::EvaluationContext.new }
    let(:object_flag) { {"key" => "value"} }
    let(:context) { OpenFeature::SDK::Hooks::Context.new(flag_key: "test", flag_type: "object", default_value: object_flag, evaluation_context:) }

    context "Requirement 4.1.1" do
      specify "Hook context MUST provide: the flag key, flag value type, evaluation context, and the default value." do
        expect(context.flag_key).to eq("test")
        expect(context.flag_type).to eq("object")
        expect(context.default_value).to eq(default_value)
        expect(context.evaluation_context).to eq(evaluation_context)
      end
    end
    context "Requirement 4.1.2" do
      let(:client_metadata) { OpenFeature::SDK::ClientMetadata.new(domain: "test") }
      let(:provider_metadata) { OpenFeature::SDK::Provider::ProviderMetadata.new(name: "provider") }
      let(:context) { OpenFeature::SDK::Hooks::Context.new(flag_key: "test", flag_type: "boolean", default_value: false, evaluation_context:, provider_metadata: provider_metadata, client_metadata: client_metadata) }

      specify "Hook context SHOULD provide: access to the provider metadata and client metadata." do
        expect(context.provider_metadata).to eq(provider_metadata)
        expect(context.client_metadata).to eq(client_metadata)
      end
    end

    context "Requirement 4.1.3" do
      specify "The flag key, flag type, and default value properties MUST be immutable." do
        expect { context.flag_key = "new" }.to raise_error(NoMethodError)
        expect { context.flag_type = "new" }.to raise_error(NoMethodError)
        expect { context.default_value = "new" }.to raise_error(NoMethodError)
        expect { context.default_value["b"] = "new" }.to raise_error(FrozenError)
      end
    end
    context "Conditional Requirement 4.1.4.1" do
      let(:client) { OpenFeature::SDK.build_client }
      specify "The evaluation context MUST be mutable only within the before hook." do
        OpenFeature::SDK.add_hook(:before) do |hook_context:, hook_hints:|
          hook_context.evaluation_context = "new"
        end
        client.fetch_boolean_value(flag_key: "test", default_value: false)
      end
    end
    context "Conditional Requirement 4.2.2.2" do
      specify "The client metadata field in the hook context MUST be immutable." do
        expect { context.client_metadata = "new" }.to raise_error(NoMethodError)
        expect { context.client_metadata.domain = "new" }.to raise_error(FrozenError)
      end
      specify "The provider metadata field in the hook context MUST be immutable." do
        expect { context.provider_metadata = "new" }.to raise_error(NoMethodError)
        expect { context.provider_metadata.name = "new" }.to raise_error(FrozenError)
      end
    end
  end
  context "4.2 Hints" do
    let(:time) { Time.now }
    subject { OpenFeature::SDK::Hooks::Hints.new("boolean" => true, "string" => "test", "number" => 1, "datetime" => time, "structure" => {a: "b"}) }
    specify "Requirement 4.2.1: MUST be a structure that supports definition of arbitrary properties, with keys of type string, and values of type boolean | string | number | datetime | structure" do
      expect(subject["boolean"]).to eq(true)
      expect(subject["string"]).to eq("test")
      expect(subject["number"]).to eq(1)
      expect(subject["datetime"]).to eq(time)
      expect(subject["structure"]).to eq({a: "b"})
    end
    context "Conditional Requirement 4.2.2.1: Hook hints MUST be immutable." do
      it "must not allow modification of the hint values" do
        expect { subject["boolean"] = false }.to raise_error(FrozenError)
      end
      it "must not allow addition of hints" do
        expect { subject["new"] = "test" }.to raise_error(FrozenError)
      end
      it "must not allow deletion of hints" do
        expect { subject.delete("boolean") }.to raise_error(FrozenError)
      end
    end
  end
  context "4.3 Hook creation and parameters" do
    let(:client) { OpenFeature::SDK.build_client }
    specify "Requirement 4.3.1: Hooks MUST specify at least one stage." do
      expect { OpenFeature::SDK.add_hooks(nil) }.to raise_error(ArgumentError)
    end
    specify "Conditional Requirement 4.3.2.1: The before stage MUST run before flag resolution occurs. It accepts a hook context (required) and hook hints (optional) as parameters and returns either an evaluation context or nothing." do
      hook = double("hook")
      allow(hook).to receive(:before).and_return(nil)
      OpenFeature::SDK.add_hooks(hook)
      client.fetch_boolean_value(flag_key: "test", default_value: false)
      expect(hook).to have_received(:before).with(hook_context: OpenFeature::SDK::Hooks::Context, hook_hints: nil)
    end
    context "Requirement 4.3.4: Any evaluation context returned from a before hook MUST be passed to subsequent before hooks (via HookContext)." do
      specify "must pass evaluation context returned from a before hook to a subsequent before hook " do
        hook = double("hook")
        hook2 = double("hook2")
        context = OpenFeature::SDK::EvaluationContext.new
        allow(hook).to receive(:before).and_return(context)
        allow(hook2).to receive(:before).and_return(nil)
        expect(hook2).to receive(:before) do |hook_context:, hook_hints:|
          expect(hook_context.evaluation_context).to eq(context)
        end
        OpenFeature::SDK.add_hooks(hook, hook2)
        client.fetch_boolean_value(flag_key: "test", default_value: false)
      end
      specify "must not pass nil evaluation context to a subsequent before hook" do
        hook = double("hook")
        hook2 = double("hook2")
        allow(hook).to receive(:before).and_return(nil)
        allow(hook2).to receive(:before)
        expect(hook2).to receive(:before) do |hook_context:, hook_hints:|
          expect(hook_context.evaluation_context).to be_a(OpenFeature::SDK::EvaluationContext)
        end
        OpenFeature::SDK.add_hooks(hook, hook2)
        client.fetch_boolean_value(flag_key: "test", default_value: false)
      end
    end
    specify "Requirement 4.3.5: When before hooks have finished executing, any resulting evaluation context MUST be merged with the existing evaluation context." do
      hook = double("hook")
      context = OpenFeature::SDK::EvaluationContext.new(before: "before")
      allow(hook).to receive(:before).and_return(context)
      OpenFeature::SDK.add_hooks(hook)
      client.fetch_boolean_value(flag_key: "test", default_value: false)
      expect(OpenFeature::SDK.evaluation_context).to have_key("before")
    end
    specify "Requirement 4.3.6: The after stage MUST run after flag resolution occurs. It accepts a hook context (required), flag evaluation details (required), and hook hints (optional) as parameters and returns nothing." do
      hook = double("hook")
      allow(hook).to receive(:after)
      OpenFeature::SDK.add_hooks(hook)
      client.fetch_boolean_value(flag_key: "test", default_value: false)
      expect(hook).to have_received(:after).with(hook_context: OpenFeature::SDK::Hooks::Context, flag_evaluation_details: OpenFeature::SDK::Provider::ResolutionDetails, hook_hints: nil)
    end
    context "Requirement 4.3.7: The error hook MUST run when errors are encountered in the before stage, the after stage or during flag resolution. It accepts hook context (required), exception representing what went wrong (required), and hook hints (optional). It has no return value" do
      let(:provider) { double("provider", metadata: provider_metadata) }
      let(:provider_metadata) { OpenFeature::SDK::Provider::ProviderMetadata.new(name: "provider") }
      specify "must run when errors are encountered in the before stage" do
        before_hook = double("before_hook")
        allow(before_hook).to receive(:before) { raise StandardError }
        error_hook = double("error_hook")
        allow(error_hook).to receive(:error)
        OpenFeature::SDK.add_hooks(before_hook, error_hook)
        client.fetch_boolean_value(flag_key: "test", default_value: false)
        expect(error_hook).to have_received(:error).with(hook_context: OpenFeature::SDK::Hooks::Context, exception: an_instance_of(StandardError), hook_hints: nil)
      end
      specify "must run when errors are encountered in the after stage" do
        after_hook = double("after_hook")
        allow(after_hook).to receive(:after) { raise StandardError }
        error_hook = double("error_hook")
        allow(error_hook).to receive(:error)
        OpenFeature::SDK.add_hooks(after_hook, error_hook)
        client.fetch_boolean_value(flag_key: "test", default_value: false)
        expect(hook).to have_received(:error).with(hook_context: OpenFeature::SDK::Hooks::Context, exception: an_instance_of(StandardError), hook_hints: nil)
      end
      specify "must run when errors are encountered during flag resolution" do
        error_hook = double("error_hook")
        allow(provider).to receive(:fetch_boolean_value) { raise StandardError }
        OpenFeature::SDK.set_provider(provider)
        allow(error_hook).to receive(:error)
        OpenFeature::SDK.add_hooks(error_hook)
        client.fetch_boolean_value(flag_key: "test", default_value: false)
        expect(error_hook).to have_received(:error).with(hook_context: OpenFeature::SDK::Hooks::Context, exception: an_instance_of(StandardError), hook_hints: nil)
      end
    end
    context "Requirement 4.3.8: The finally hook MUST run after the before, after, and error stages. It accepts a hook context (required) and hook hints (optional). There is no return value." do
      specify "must run when flag resolution and hooks succeed" do
        hook = double("hook")
        expect(hook).to receive(:before).ordered
        expect(hook).to receive(:after).ordered
        expect(hook).to receive(:finally).ordered.with(hook_context: OpenFeature::SDK::Hooks::Context, hook_hints: nil)
        OpenFeature::SDK.add_hooks(hook)
        client.fetch_boolean_value(flag_key: "test", default_value: false)
      end
    end
  end
end
