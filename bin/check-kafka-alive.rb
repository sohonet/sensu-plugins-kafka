#! /usr/bin/env ruby
#
# check-kafka-alive
#
# DESCRIPTION:
#   This plugin checks kafka is responding
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: ruby-kafka
#
# USAGE:
#   ./check-kafka-alive
#
# NOTES:
#
# LICENSE:
#   Johan van den Dorpe
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'kafka'

class KafkaAliveCheck < Sensu::Plugin::Check::CLI
  option :bootstrap_servers,
         description: 'Comma seperated list of Kafka servers and ports: kafka-01:9092,kafka-02:9092 ...',
         short:       '-b KAFKA:9092',
         long:        '--bootstrap_servers KAFKA:9092',
         default:     'localhost:9092',
         proc:        Proc.new { |b| b.split(',') },
         required:    true

  def run
    kafka = Kafka.new(config[:bootstrap_servers], client_id: "check-kafka")
    topics = kafka.topics
    ok
  rescue => e
    puts "Error: #{e.backtrace}"
    critical "Error: #{e}"
  end
end
