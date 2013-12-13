#!/usr/bin/env ruby

require 'json'
require 'erb'
require 'fileutils'
require 'json-schema'
require 'rakejava'
require 'yard'

$LOAD_PATH << "#{File.dirname(__FILE__)}/lib"
require 'protocol_generator/utils'
require 'protocol_generator/parser'
require 'protocol_generator/generators'
require 'protocol_generator/errors'

module ProtocolGenerator

  def self.version
    1
  end

  def self.print_usage_and_exit
    puts "Usage: ruby #{__FILE__} <protofile_path_1> <protofile_path_2> ... <conf_path>"
    puts "where protofile_path is the path to the protocol definition file,"
    puts "where conf_path is the path to the integration configuration file."
    exit 1
  end

  begin
    puts "ProtocolGenerator, version #{ProtocolGenerator.version}"
    if (ARGV[0].nil? || ARGV[1].nil?)
      print_usage_and_exit
    end
    unless File.exists?(ARGV[0])
      raise Error::ProtocolFileNotFound.new("Protocol description file not found at #{ARGV[0]}")
    end
    (0...ARGV.size - 1).each do |i|
      unless File.exists?(ARGV[i])
        raise Error::ConfigurationFileError.new("Configuration file not found at #{ARGV[i]}")
      end
    end
    params = {}
    params['config_path'] = ARGV.last
    params['default_config_path'] = File.join(File.dirname(__FILE__), "config", "config.json")
    params['temp_output_directory'] = "/tmp/protogen_#{Time.now.to_i}"
    params['protocol_path'] = ARGV[(0...ARGV.size - 1)]
    puts "Parsing protocol and configuration files..."
    protocol_set = Parser.run(params)
    puts "Running plugins to generate code..."
    Generator::Manager.run(protocol_set.config.get(:global, :plugins).map { |e| e.to_sym }, protocol_set)
  rescue Error::ProtogenError => e
    puts "Protogen encountered an error while generating code: #{e.class.name}"
    puts e.message
    puts e.backtrace.join("\n")
    puts "Exiting with code #{e.exit_code} (#{Error::ERROR_CODE.key(e.exit_code)})"
    exit e.exit_code
  rescue StandardError => e
    puts "Protogen encountered an error while generating code: #{e.class.name}"
    puts e.message
    puts e.backtrace.join("\n")
    puts "Exiting with code 1"
    exit 1
  end
  puts "Exiting with code 0 (no unhandled errors)"
  exit 0
end
