# frozen_string_literal: true

module ConcurrencyHelper
  private

  attr_reader :threads

  def in_thread(*arguments, &block)
    @threads ||= Queue.new
    new_thread = Thread.new(*arguments) do |*args, &b|
      Thread.abort_on_exception = true
      sleep(rand(0.1))
      block.call(*args, &b)
    end
    @threads << new_thread
    new_thread
  end
end

RSpec.configure do |config|
  config.after do
    if defined?(@threads)
      @threads.pop.join until @threads.empty?
    end
  end
  config.include(ConcurrencyHelper)
end
