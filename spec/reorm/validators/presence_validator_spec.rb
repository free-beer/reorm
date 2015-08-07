require "spec_helper"

describe Reorm::PresenceValidator do
  subject {
    Reorm::PresenceValidator.new(:one, :two, :three)
  }
  let(:object) {
    obj = OpenStruct.new(errors: Reorm::PropertyErrors.new)
    obj.define_singleton_method(:include?) {|key| obj.to_h.include?(key)}
    obj
  }
  let(:path) {
    "one -> two -> three".to_sym
  }

  it "sets no errors if the object passed to it possesses the required field value" do
    object.one = {two: {three: 3}}
    subject.validate(object)
    expect(object.errors.clear?).to eq(true)
  end

  it "sets an error if the object passed in does not possess the required field" do
    subject.validate(object)
    expect(object.errors.clear?).to eq(false)
    expect(object.errors.properties).to include(path)
    expect(object.errors.messages(path)).to include("cannot be blank.")
  end

  it "sets an error if the object passed has a blank string field value" do
    object.one = {two: {three: ""}}
    subject.validate(object)
    expect(object.errors.clear?).to eq(false)
    expect(object.errors.properties).to include(path)
    expect(object.errors.messages(path)).to include("cannot be blank.")
  end

  it "sets an error if the object passed has a blank string field value" do
    object.one = {two: {three: nil}}
    subject.validate(object)
    expect(object.errors.clear?).to eq(false)
    expect(object.errors.properties).to include(path)
    expect(object.errors.messages(path)).to include("cannot be blank.")
  end
end
