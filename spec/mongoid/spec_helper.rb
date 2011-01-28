require 'spec_helper'
require 'mongoid'
# require 'bson_ext' 

config = YAML.load(File.read('spec/mongoid/mongoid.yml'))['test']

Mongoid.configure.master = Mongo::Connection.new.db(config['database'])

class DelayedJob
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :handler,     :type => String

  field :priority,    :type => Integer, :default => 0
  field :attempts,    :type => Integer, :default => 0

  field :last_error,  :type => String
  field :run_at,      :type => Time
  field :locked_at,      :type => Time
  field :failed_at,      :type => Time
  field :locked_by,      :type => String

  # index(
  #   [
  #     [ :priority,  Mongo::DESCENDING ],
  #     [ :run_at,    Mongo::ASCENDING  ]
  #   ],
  #   :unique => true
  # )
  
  # add_index :delayed_jobs, [:priority, :run_at], :name => 'delayed_jobs_priority'  
end

class Story
  include Mongoid::Document
  
  field :text, :type => String
end

# Purely useful for test cases...
class Story
  def tell 
    text 
  end
  
  def whatever(n, _)
    tell*n
  end

  handle_asynchronously :whatever
end

Delayed::Worker.backend = :mongoid

# Add this directory so the ActiveSupport autoloading works
ActiveSupport::Dependencies.autoload_paths << File.dirname(__FILE__)

# Add this to simulate Railtie initializer being executed
ActionMailer::Base.send(:extend, Delayed::DelayMail)
