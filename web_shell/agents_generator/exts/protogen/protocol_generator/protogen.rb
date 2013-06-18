#!/usr/bin/env ruby

require 'json'
require 'erb'
require 'fileutils'
require 'json-schema'
require 'rakejava'


$LOAD_PATH << "#{File.dirname(__FILE__)}/lib"
require 'protocol_generator/environment'
require 'protocol_generator/utils'
require 'protocol_generator/parser'
require 'protocol_generator/generators'

module ProtocolGenerator
  def self.print_usage_and_exit
    puts "Usage: ruby #{__FILE__} <protofile_path> <conf_path>"
    puts "where protofile_path is the path to the protocol definition file,"
    puts "where conf_path is the path to the integration configuration file."
    exit 1
  end
  if (ARGV[0].nil? || !File.exists?(ARGV[0]) || ARGV[1].nil? || !File.exists?(ARGV[1]))
    print_usage_and_exit
  end
  Environment.init(ARGV[0], ARGV[1], ARGV[2] || "protogen_#{Time.now.to_i}")
  Parser.run
  Generator::Manager.run(Env['plugins'].map { |e| e.to_sym })
end



