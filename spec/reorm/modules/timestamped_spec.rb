require "spec_helper"

class TimestampedTestClass < Reorm::Model
	include Reorm::Timestamped
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

	it "set the update_at field when a record is updated" do
		record = subject.create(label: "Second")
		created = record.created_at.to_i
		sleep(0.2)

		record.label = "Updated"
		record.save
		expect(record.created_at.to_i).to eq(created)
		expect(record.updated_at).not_to be_nil
	end
end
