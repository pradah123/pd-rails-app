#!/usr/bin/env ruby
ENV['RAILS_ENV'] = "development" # Set to your desired Rails environment name
require './region.rb'
require 'observation.rb'
require 'participation.rb'
require 'contest.rb'
require 'data_source.rb'


puts 'What is your name?'

puts Region.where(id: 154).first;

