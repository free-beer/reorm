require "spec_helper"

describe Reorm::ExclusionValidator do
  subject {
    Reorm::ExclusionValidator.new([1, 3, 5], :one, :two, :three)
  }
  let(:object) {
    obj = OpenStruct.new(errors: Reorm::PropertyErrors.new)
    obj.define_singleton_method(:include?) {|key| obj.to_h.include?(key)}
    obj
  }
  let(:path) {
    "one -> two -> three".to_sym
  }

  it "sets no errors if the object passed to it possesses doesn't have a field value matching one of the excluded values" do
    object.one = {two: {three: 2}}
    subject.validate(object)
    expect(object.errors.clear?).to eq(true)
  end

  it "sets no errors if the object passed in does not possess the field value" do
    subject.validate(object)
    expect(object.errors.clear?).to eq(true)
  end

  it "sets an error if the object passed in has a field value that does match one of the excluded values" do
    object.one = {two: {three: 5}}
    subject.validate(object)
    expect(object.errors.clear?).to eq(false)
    expect(object.errors.properties).to include(path)
    expect(object.errors.messages(path)).to include("is set to an unpermitted value.")
  end
end
