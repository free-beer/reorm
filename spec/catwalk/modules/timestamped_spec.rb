require "spec_helper"

class TimestampedTestClass < Reorm::Model
	extend Reorm::Timestamped
end

describe Reorm::Timestamped do
	subject {
		TimestampedTestClass
	}

	it "set the timestamp fields when a record is created" do
		record = subject.create(label: "First")
		expect(record.created_at).not_to be_nil
		expect(record.updated_at).to be_nil
	end
end
