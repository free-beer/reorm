require "spec_helper"

describe Reorm::Validator do
  subject {
    Reorm::Validator.new("This is the message text.", :one, :two, :three)
  }

  describe "#field()" do
    it "returns a FieldPath object" do
      expect(subject.field.class).to eq(Reorm::FieldPath)
    end

    it "refers to the field specified when the object was created" do
      expect(subject.field.to_s).to eq("one -> two -> three")
    end
  end

  describe "#message()" do
    it "returns the message set for the validator" do
      expect(subject.message).to eq("This is the message text.")
    end
  end
end
