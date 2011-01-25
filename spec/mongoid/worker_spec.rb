require 'mongoid/spec_helper'

describe Delayed::Worker do
  describe "backend=" do
    before do
      @clazz = Class.new
      Delayed::Worker.backend = @clazz
    end

    it "should set the Delayed::Job constant to the backend" do
      Delayed::Job.should == @clazz
    end

    it "should set backend with a symbol" do
      Delayed::Worker.backend = :mongoid
      Delayed::Worker.backend.should == Delayed::Backend::Mongoid::Job
    end
  end

  describe "guess_backend" do
    after do
      Delayed::Worker.backend = :mongoid
    end

    it "should set to active_record if nil" do
      Delayed::Worker.backend = nil
      lambda {
        Delayed::Worker.guess_backend
      }.should change { Delayed::Worker.backend }.to(Delayed::Backend::Mongoid::Job)
    end

    it "should not override the existing backend" do
      Delayed::Worker.backend = Class.new
      lambda { Delayed::Worker.guess_backend }.should_not change { Delayed::Worker.backend }
    end
  end
end
