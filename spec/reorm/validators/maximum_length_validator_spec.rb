require "spec_helper"

describe Reorm::MaximumLengthValidator do
  subject {
    Reorm::MaximumLengthValidator.new(5, :one, :two, :three)
  }
  let(:object) {
    obj = OpenStruct.new(errors: Reorm::PropertyErrors.new)
    obj.define_singleton_method(:include?) {|key| obj.to_h.include?(key)}
    obj
  }
  let(:path) {
    "one -> two -> three".to_sym
  }

  it "does not set an error if the objects field value is short than or equal to the permitted length" do
    object.one = {two: {three: "123"}}
    subject.validate(object)
    expect(object.errors.clear?).to eq(true)
    object.one = {two: {three: "12345"}}
    subject.validate(object)
    expect(object.errors.clear?).to eq(true)
  end

  it "does not set an error if the object does not possess a value for the field" do
    subject.validate(object)
    expect(object.errors.clear?).to eq(true)
  end

  it "sets an error if the objects field value is longer than that permitted length" do
    object.one = {two: {three: "123456"}}
    subject.validate(object)
    expect(object.errors.clear?).to eq(false)
    expect(object.errors.properties).to include(path)
    expect(object.errors.messages(path)).to include("is too long (maximum length is 5 characters).")
  end
end
