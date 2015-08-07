require "spec_helper"

class ValidationsTestClass < Reorm::Model
  include Reorm::Validations

  def initialize(properties={})
    super(properties)
    @errors = Reorm::PropertyErrors.new
  end
  attr_reader :errors

  def include?(property)
    to_h.include?(property)
  end
end

describe Reorm::Validations do
  subject {
    ValidationsTestClass.new
  }
  let(:path) {
    "one -> two -> three".to_sym
  }

  describe "#validate_presence_of()" do
    it "does not set an error if the field value is set" do
      subject.one = {two: {three: 3}}
      subject.validate_presence_of([:one, :two, :three])
      expect(subject.errors.clear?).to eq(true)
    end

    it "sets an error if the object does not possess the field value" do
      subject.validate_presence_of([:one, :two, :three])
      expect(subject.errors.clear?).to eq(false)
      expect(subject.errors).to include(path)
      expect(subject.errors.messages(path)).to include("cannot be blank.")
    end

    it "sets an error if the object does possess the field value but its a blank string" do
      subject.one = {two: {three: ""}}
      subject.validate_presence_of([:one, :two, :three])
      expect(subject.errors.clear?).to eq(false)
      expect(subject.errors).to include(path)
      expect(subject.errors.messages(path)).to include("cannot be blank.")
    end

    it "sets an error if the object does possess the field value but its nil" do
      subject.one = {two: {three: nil}}
      subject.validate_presence_of([:one, :two, :three])
      expect(subject.errors.clear?).to eq(false)
      expect(subject.errors).to include(path)
      expect(subject.errors.messages(path)).to include("cannot be blank.")
    end
  end

  describe "#validate_length_of()" do
    describe "with a minimum setting" do
      it "does not set an error if the object as a field value that exceeds the minimum length" do
        subject.one = {two: {three: "12345"}}
        subject.validate_length_of([:one, :two, :three], minimum: 3)
        expect(subject.errors.clear?).to eq(true)
      end

      it "does not set an error if the object as a field value that equals the minimum length" do
        subject.one = {two: {three: "123"}}
        subject.validate_length_of([:one, :two, :three], minimum: 3)
        expect(subject.errors.clear?).to eq(true)
      end

      it "does not set an error if the object does not possess the field value" do
        subject.validate_length_of([:one, :two, :three], minimum: 3)
        expect(subject.errors.clear?).to eq(false)
        expect(subject.errors).to include(path)
        expect(subject.errors.messages(path)).to include("is too short (minimum length is 3 characters).")
      end

      it "does set an error if the object has a field value that is less than the minimum length" do
        subject.one = {two: {three: "12"}}
        subject.validate_length_of([:one, :two, :three], minimum: 3)
        expect(subject.errors.clear?).to eq(false)
        expect(subject.errors).to include(path)
        expect(subject.errors.messages(path)).to include("is too short (minimum length is 3 characters).")
      end
    end

    describe "with a maximum setting" do
      it "does not set an error if the object as a field value that is less than the maximum length" do
        subject.one = {two: {three: "12"}}
        subject.validate_length_of([:one, :two, :three], maximum: 3)
        expect(subject.errors.clear?).to eq(true)
      end

      it "does not set an error if the object as a field value that equals the maximum length" do
        subject.one = {two: {three: "123"}}
        subject.validate_length_of([:one, :two, :three], maximum: 3)
        expect(subject.errors.clear?).to eq(true)
      end

      it "does not set an error if the object does not possess the field value" do
        subject.validate_length_of([:one, :two, :three], maximum: 3)
        expect(subject.errors.clear?).to eq(true)
      end

      it "does set an error if the object has a field value that is greater than the maximum length" do
        subject.one = {two: {three: "1234"}}
        subject.validate_length_of([:one, :two, :three], maximum: 3)
        expect(subject.errors.clear?).to eq(false)
        expect(subject.errors).to include(path)
        expect(subject.errors.messages(path)).to include("is too long (maximum length is 3 characters).")
      end
    end
  end

  describe "#validate_inclusion_of()" do
    it "does not set an error if the object field value is one of the permitted set" do
      subject.one = {two: {three: 3}}
      subject.validate_inclusion_of([:one, :two, :three], 1, 2, 3, 4, 5)
      expect(subject.errors.clear?).to eq(true)
    end

    it "does set an error if the object does not possess the field value" do
      subject.validate_inclusion_of([:one, :two, :three], 1, 2, 3, 4, 5)
      expect(subject.errors.clear?).to eq(false)
      expect(subject.errors).to include(path)
      expect(subject.errors.messages(path)).to include("is not set to one of its permitted values.")
    end

    it "does set an error if the object field value is not one of the permitted set" do
      subject.one = {two: {three: 17}}
      subject.validate_inclusion_of([:one, :two, :three], 1, 2, 3, 4, 5)
      expect(subject.errors.clear?).to eq(false)
      expect(subject.errors).to include(path)
      expect(subject.errors.messages(path)).to include("is not set to one of its permitted values.")
    end
  end

  describe "#validate_exclusion_of()" do
    it "does not set an error if the object field value is not one of the excluded set" do
      subject.one = {two: {three: 10}}
      subject.validate_exclusion_of([:one, :two, :three], 1, 2, 3, 4, 5)
      expect(subject.errors.clear?).to eq(true)
    end

    it "does not set an error if the object does not possess the field value" do
      subject.validate_exclusion_of([:one, :two, :three], 1, 2, 3, 4, 5)
      expect(subject.errors.clear?).to eq(true)
    end

    it "it does set an error if the object field value is one of the excluded set" do
      subject.one = {two: {three: 4}}
      subject.validate_exclusion_of([:one, :two, :three], 1, 2, 3, 4, 5)
      expect(subject.errors.clear?).to eq(false)
      expect(subject.errors).to include(path)
      expect(subject.errors.messages(path)).to include("is set to an unpermitted value.")
    end
  end
end
