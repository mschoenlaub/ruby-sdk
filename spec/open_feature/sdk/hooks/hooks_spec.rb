# frozen_string_literal: true

require "spec_helper"
require "open_feature/sdk/hooks/hookable"

class DummyHookable
  include OpenFeature::SDK::Hooks::Hookable
end

RSpec.describe "OpenFeature::SDK::Hookable" do
  subject { DummyHookable.new }
  context "Registration" do
    it "throws an error if the hook does not support the given stage" do
      expect { subject.add_hook(:before, "test") }.to raise_error(ArgumentError)
    end
    it "throws an error if both a hook and a block are provided" do
      expect { subject.add_hook(:before, "test") { "test" } }.to raise_error(ArgumentError)
    end
    it "throws an error if neither a hook nor a block are provided" do
      expect { subject.add_hook(:before) }.to raise_error(ArgumentError)
    end
    it "throws an error if the hook is for an unknown stage" do
      expect { subject.add_hook(:unknown, "test") }.to raise_error(ArgumentError)
    end
    it "adds a hook to the before stage if given a block" do
      subject.add_hook(:before) { "test" }
      expect(subject.hooks[:before].length).to eq(1)
    end
    it "adds a hook to the before stage if the object is a callable" do
      subject.add_hook(:before, double(call: "test"))
      expect(subject.hooks[:before].length).to eq(1)
    end
    it "adds a hook to the before stage if the object responds to the given stage" do
      subject.add_hook(:before, double(before: "test"))
      expect(subject.hooks[:before].length).to eq(1)
    end
  end
  context "Thread Safety" do
    it "synchronizes access to the hooks" do
      hook = double(call: "test")
      (1..1000).map do |i|
        in_thread do
          subject.add_hook(:before, hook)
          expect(subject.hooks[:before]).to_not be_empty
        end
      end.map { |t| t.join }
      expect(subject.hooks[:before].length).to eq(100000)
    end
  end
end
