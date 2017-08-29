#! /usr/bin/env ruby
#
# metrics-consumer-kafka
#
# DESCRIPTION:
#   Gets consumers's offset, logsize and lag metrics from Kafka and puts them in Graphite for longer term storage
#
# OUTPUT:
#   metric-data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   #YELLOW
#
#
# LICENSE:
#   Copyright 2017 Sohonet Ltd
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'popen4'
require 'pry'

class ConsumerOffsetMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: 'sensu.kafka.consumers'

  option :group,
         description: 'Consumer group',
         short:       '-g NAME',
         long:        '--group NAME',
         required:    true

  option :kafka_home,
         description: 'Kafka home',
         short:       '-k NAME',
         long:        '--kafka-home NAME',
         default:     '/opt/kafka'

  option :topic,
         description: 'Comma-separated list of consumer topics',
         short:       '-t NAME',
         long:        '--topic NAME',
         proc:        proc { |a| a.split(',') }

  option :topic_excludes,
         description: 'Excludes consumer topics',
         short:       '-e NAME',
         long:        '--topic-excludes NAME',
         proc:        proc { |a| a.split(',') }

  option :bootstrap,
         description: 'Kafka bootstrap server',
         short:       '-b NAME',
         long:        '--bootstrap NAME',
         default:     'localhost:9092'

  def read_lines(command)
    output = %x{#{command}}
    return output.split("\n") if $?.success?

    unknown "Command #{command} failed: #{output}"
  end

  # create a hash from the output of each line of a command
  # @param line [String]
  # @param cols
  def line_to_hash(line, *cols)
    Hash[cols.zip(line.strip.split(/\s+/, cols.size))]
  end

  # run command and return a hash from the output
  # @param cmd [String]
  def run_cmd(cmd)
    read_lines(cmd).map do |line|
      if line =~ /^Error/
        unknown "Error running #{cmd}"
      end
      next if line !~ /^[a-z]/
      line_to_hash(line, :topic, :partition, :offset, :logsize, :lag, :id, :host, :client_id)
    end
  end

  def run
    begin

      kafka_consumer_groups = "#{config[:kafka_home]}/bin/kafka-consumer-groups.sh"
      unknown "Can not find #{kafka_consumer_groups}" unless File.exist?(kafka_consumer_groups)

      cmd = "#{kafka_consumer_groups} --group #{config[:group]} --describe"
      cmd += " --zookeeper #{config[:zookeeper]}" if config[:zookeeper]
      cmd += " --bootstrap-server #{config[:bootstrap]}" if config[:bootstrap]
      cmd += " --topic #{config[:topic]}" if config[:topic]
      cmd += " 2>&1"
      puts cmd

      results = run_cmd(cmd).compact

      [:offset, :logsize, :lag].each do |field|
        sum_by_group = results.group_by { |h| h[:topic] }.map do |k, v|
          Hash[k, v.inject(0) { |a, e| a + e[field].to_i }]
        end
        sum_by_group.delete_if { |x| config[:topic_excludes].include?(x.keys[0]) } if config[:topic_excludes]
        sum_by_group.each do |x|
          output "#{config[:scheme]}.#{config[:group]}.#{x.keys[0]}.#{field}", x.values[0]
        end
      end
    rescue => e
      critical "Error: exception: #{e}"
    end
    ok
  end
end
