require 'rubygems'
require 'bundler/setup'
require 'rspec/core'
require 'logger'

require 'rails'
require 'action_mailer'

require 'delayed_job'
require 'delayed/backend/shared_spec'

Delayed::Worker.logger = Logger.new('/tmp/dj.log')
ENV['RAILS_ENV'] = 'test'