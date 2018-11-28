# frozen_string_literal: true

require 'bundler/setup'
require 'chain_options'

require 'simplecov'
SimpleCov.start

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
