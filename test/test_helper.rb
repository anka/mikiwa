require "simplecov"
SimpleCov.start "rails" do
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/db/"
  minimum_coverage 85
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    parallelize_setup do |worker|
      SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"
    end

    parallelize_teardown do |_worker|
      SimpleCov.result
    end

    fixtures :all

    # Lightweight singleton-method stub. Minitest 6 ships without
    # Object#stub, so we provide equivalent semantics that works for both
    # class- and instance-level singletons.
    #
    #   with_stub(ShoppingItems::AutoClassifier, :call, :fruit) { … }
    def with_stub(target, method_name, value)
      sclass     = target.singleton_class
      original   = :"__orig_#{method_name}_#{object_id}"
      had_method = target.respond_to?(method_name)
      sclass.send(:alias_method, original, method_name) if had_method
      target.define_singleton_method(method_name) { |*_args, **_kwargs| value }
      yield
    ensure
      sclass.send(:remove_method, method_name) if sclass.method_defined?(method_name) || sclass.private_method_defined?(method_name)
      if had_method && (sclass.method_defined?(original) || sclass.private_method_defined?(original))
        sclass.send(:alias_method, method_name, original)
        sclass.send(:remove_method, original)
      end
    end
  end
end
