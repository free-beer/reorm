require "spec_helper"

describe Reorm::PropertyErrors do
	subject {
		Reorm::PropertyErrors.new
	}

	describe "#clear?()" do
		it "returns true for an empty instance" do
			expect(subject.clear?).to eq(true)
		end

		it "returns false for a non-empty instance" do
			subject.add(:blah, "Some message.")
			expect(subject.clear?).to eq(false)
		end
	end

	describe "#reset()" do
		before do
			subject.add(:field1, "Message 1.")
			subject.add(:field2, "Message 2.")
			subject.add(:field3, "Message 3.")
		end

		it "removes any existing errors" do
			subject.reset
			expect(subject.clear?).to eq(true)
		end
	end

	describe "#include?()" do
		before do
			subject.add(:field1, "An error message.")
		end

		it "returns false if there are no errors for the specified property" do
			expect(subject.include?(:blah)).to eq(false)
		end

		it "returns true if there are errors for the specified property" do
			expect(subject.include?(:field1)).to eq(true)
		end
	end

	describe "#add()" do
		it "adds an error message for a given property" do
			subject.add(:field1, "The error message for field 1.")
			expect(subject.include?(:field1)).to eq(true)
			expect(subject.messages(:field1)).to eq(["The error message for field 1."])
		end

		it "does not add an error if the message is blank" do
			subject.add(:field1, nil)
			expect(subject.clear?).to eq(true)
			subject.add(:field1, "")
			expect(subject.clear?).to eq(true)
		end
	end

	describe "#prperties()" do
		it "returns an empty array if called when there are no errors" do
			expect(subject.properties).to eq([])
		end

		it "returns an array with properties and no duplicates if there are errors" do
			subject.add(:field1, "First error.")
			subject.add(:field2, "Second error.")
			subject.add(:field1, "Third error.")
			expect(subject.properties).to eq([:field1, :field2])
		end
	end

	describe "#messages()" do
		it "returns an empty array where there are no messages for the specified property" do
			expect(subject.messages(:blah)).to eq([])
		end

		it "returns an array of messages where there are message for the specified property" do
			subject.add(:field1, "First error.")
			subject.add(:field2, "Second error.")
			subject.add(:field1, "Third error.")
			expect(subject.messages(:field1)).to eq(["First error.", "Third error."])
		end
	end

	describe "#each()" do
		it "yields a property name and message array to the specified block" do
			subject.add(:first, "A message.")
			subject.each do |property, messages|
				expect(property).to eq(:first)
				expect(messages).to eq(["A message."])
			end
		end

		it "yields once for each property with errors" do
			subject.add(:field1, "An error.")
			subject.add(:field1, "An error.")
			subject.add(:field2, "An error.")
			total = 0
			subject.each {|property, messages| total += 1}
			expect(total).to eq(2)
		end
	end

	describe "#to_s" do
		it "returns an empty string when there are no errors" do
			expect(subject.to_s).to eq("")
		end

		it "returns a string containing one error per line when there are errors" do
			subject.add(:field1, "has an error.")
			subject.add(:field1, "has another error.")
			subject.add(:field2, "also has an error.")
			expect(subject.to_s).to eq("field1 has an error.\n"\
			                           "field1 has another error.\n"\
																 "field2 also has an error.")
		end
	end
end
