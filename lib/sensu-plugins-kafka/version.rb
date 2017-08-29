require 'json'

# encoding: utf-8
module SensuPluginsKafka
  # This defines the version of the gem
  module Version
    MAJOR = 0
    MINOR = 8
    PATCH = 3

    VER_STRING = [MAJOR, MINOR, PATCH, 'sohonet'].compact.join('.')
  end
end
