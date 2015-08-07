require "spec_helper"

class EventSourceTest
  include Reorm::EventHandler
  include Reorm::EventSource
  extend Reorm::EventHandler
  extend Reorm::EventSource

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
    describe "called at the instance level" do
      it "calls methods assigned to events when those events are fired" do
        subject.before_create :event_handler
        subject.fire_events(events: [:before_create])
        expect(subject.count).to eq(1)
      end
    end

    describe "called at the class level" do
      it "calls methods assigned to events when those events are fired" do
        EventSourceTest.before_create :event_handler
        EventSourceTest.fire_events({target: subject, events: [:before_create]})
        expect(subject.count).to eq(1)
      end
    end
  end
end
