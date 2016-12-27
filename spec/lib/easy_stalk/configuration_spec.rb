require 'spec_helper'

describe EasyStalk::Configuration do
  describe "#logger" do
    specify "gets the default logger" do
      expect(subject.logger).to be_a Logger
      expect(subject.logger.progname).to eq EasyStalk.name
    end
  end
  describe "#logger=" do
    specify "sets the default logger" do
      subject.logger = "cat"
      expect(subject.logger).to eq "cat"
    end
  end

  describe "#worker_on_fail" do
    specify "gets the default logger" do
      expect(subject.worker_on_fail).to be_a Proc
    end
  end
  describe "#worker_on_fail=" do
    specify "sets the default on_fail proc" do
      subject.worker_on_fail = "cat"
      expect(subject.worker_on_fail).to eq "cat"
    end
  end

end
