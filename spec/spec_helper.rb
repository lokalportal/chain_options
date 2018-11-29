# frozen_string_literal: true

require 'bundler/setup'
require 'pry'
require 'pry-byebug'
require 'chain_options'

require 'simplecov'
SimpleCov.start

if defined?(PryByebug)
  Pry.commands.alias_command 'c', 'continue'
  Pry.commands.alias_command 's', 'step'
  Pry.commands.alias_command 'n', 'next'
  Pry.commands.alias_command 'f', 'finish'
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
