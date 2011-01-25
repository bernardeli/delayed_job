module Mongoid::Document
  yaml_as "tag:ruby.yaml.org,2002:Mongoid"

  def self.yaml_new(klass, tag, val)
    klass.find(val['attributes']['id'])
  rescue
    raise Delayed::DeserializationError
  end

  def to_yaml_properties
    ['@attributes']
  end
end
