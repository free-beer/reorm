require "spec_helper"

describe Reorm::MinimumLengthValidator do
  subject {
    Reorm::MinimumLengthValidator.new(5, :one, :two, :three)
  }
  let(:object) {
    obj = OpenStruct.new(errors: Reorm::PropertyErrors.new)
    obj.define_singleton_method(:include?) {|key| obj.to_h.include?(key)}
    obj
  }
  let(:path) {
    "one -> two -> three".to_sym
  }

  it "does not set an error if the objects field value is greater than or equal to the permitted length" do
    object.one = {two: {three: "1234567"}}
    subject.validate(object)
    expect(object.errors.clear?).to eq(true)
    object.one = {two: {three: "12345"}}
    subject.validate(object)
    expect(object.errors.clear?).to eq(true)
  end

  it "does not set an error if the object does not possess a value for the field" do
    subject.validate(object)
    expect(object.errors.clear?).to eq(false)
    expect(object.errors.properties).to include(path)
    expect(object.errors.messages(path)).to include("is too short (minimum length is 5 characters).")
  end

  it "sets an error if the objects field value is longer than that permitted length" do
    object.one = {two: {three: "123"}}
    subject.validate(object)
    expect(object.errors.clear?).to eq(false)
    expect(object.errors.properties).to include(path)
    expect(object.errors.messages(path)).to include("is too short (minimum length is 5 characters).")
  end
end
