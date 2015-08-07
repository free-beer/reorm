require "spec_helper"

describe Reorm::FieldPath do
  describe "#name()" do
    subject {
      Reorm::FieldPath.new(:first, :second, :third)
    }

    it "returns the last element of the field path as the name" do
      expect(subject.name).to eq(:third)
    end
  end

  describe "#value()" do
    it "fetches the value from the input" do
      field = Reorm::FieldPath.new(:first)
      expect(field.value({first: 1})).to eq(1)
    end

    it "traverses a hierarchy if one has been specified" do
    field = Reorm::FieldPath.new(:first, :second, :third)
    expect(field.value({first: {second: {third: 3}}})).to eq(3)
    end

    it "returns nil of the field does not exist" do
      field = Reorm::FieldPath.new(:first, :second, :third)
      expect(field.value({first: 1})).to be_nil
    end
  end

  describe "#value!()" do
    it "raises an exception if the value does not exist" do
      field = Reorm::FieldPath.new(:first, :second, :third)
      expect {
        field.value!({first: 1})
      }.to raise_exception(Reorm::Error, "Unable to locate the #{field.name} (full path: #{field}) field for an instance of the Hash class.")
    end
  end

  describe "#exists?()" do
    subject {
      Reorm::FieldPath.new(:first, :second, :third)
    }

    it "returns true if the field exists within the specified document" do
      expect(subject.exists?({first: {second: {third: 3}}})).to eq(true)
    end

    it "returns false if the field does not exist within the specified document" do
      expect(subject.exists?({first: 1})).to eq(false)
    end
  end

  describe "#to_s" do
    it "returns the correct value for a simple field path" do
      field = Reorm::FieldPath.new(:first)
      expect(field.to_s).to eq("first")
    end

    it "returns the correct value for a more complicated field path" do
      field = Reorm::FieldPath.new(:first, :second, :third)
      expect(field.to_s).to eq("first -> second -> third")
    end
  end
end
