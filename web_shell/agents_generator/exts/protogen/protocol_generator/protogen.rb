#!/usr/bin/env ruby

require 'json'
require 'erb'
require 'fileutils'
require 'json-schema'
require 'rakejava'
require 'yard'

$LOAD_PATH << "#{File.dirname(__FILE__)}/lib"
require 'protocol_generator/environment'
require 'protocol_generator/utils'
require 'protocol_generator/parser'
require 'protocol_generator/generators'
require 'protocol_generator/errors'

module ProtocolGenerator

  def self.print_usage_and_exit
    puts "Usage: ruby #{__FILE__} <protofile_path> <conf_path>"
    puts "where protofile_path is the path to the protocol definition file,"
    puts "where conf_path is the path to the integration configuration file."
    exit 1
  end

  begin
    Environment.init
    puts "ProtocolGenerator, version #{ProtocolGenerator.version}"
    if (ARGV[0].nil? || ARGV[1].nil?)
      print_usage_and_exit
    end
    unless File.exists?(ARGV[0])
      raise Error::ProtocolFileNotFound.new("Protocol description file not found at #{ARGV[0]}")
    end
    unless File.exists?(ARGV[1])
      raise Error::ConfigurationFileError.new("Configuration file not found at #{ARGV[1]}")
    end
    Env['input_path'] = ARGV[0]
    Env['conf_file_path'] = ARGV[1]
    Env['output_directory'] = ARGV[2] || "protogen_#{Time.now.to_i}"
    puts "Parsing protocol and configuration files"
    Parser.run
    puts "Running plugins to generate code"
    Generator::Manager.run(Env['plugins'].map { |e| e.to_sym })
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
