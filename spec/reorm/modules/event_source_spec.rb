require "spec_helper"

class EventSourceTest
  include Reorm::EventHandler
  include Reorm::EventSource

  before_create :event_handler
  before_validate :does_not_exist

  def initialize
    @count = 0
  end
  attr_reader :count

  def reset
    @count = 0
  end

  def event_handler
    @count += 1
  end
end

describe EventSourceTest do
  subject {
    EventSourceTest.new
  }

  before do
    subject.reset
  end

  describe "#fire_events()" do
    describe "called at the class level" do
      it "calls methods assigned to events when those events are fired" do
        EventSourceTest.before_create :event_handler
        EventSourceTest.fire_events({target: subject, events: [:before_create]})
        expect(subject.count).to eq(1)
      end
    end

    it "raises an exception if an event that has been specified does not exist" do
      expect {
        subject.fire_events(target: subject, events: [:before_validate])
      }.to raise_exception(Reorm::Error, "Unable to locate a method called 'does_not_exist' for an instance of the EventSourceTest class.")
    end
  end
end
