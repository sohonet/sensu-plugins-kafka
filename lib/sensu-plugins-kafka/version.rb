require 'json'

# encoding: utf-8
module SensuPluginsKafka
  # This defines the version of the gem
  module Version
    MAJOR = 0
    MINOR = 2
    PATCH = 1

    VER_STRING = [MAJOR, MINOR, PATCH].compact.join('.')
  end
end
