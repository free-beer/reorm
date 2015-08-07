require "spec_helper"

describe Reorm::InclusionValidator do
  subject {
    Reorm::InclusionValidator.new([1, 3, 5], :one, :two, :three)
  }
  let(:object) {
    obj = OpenStruct.new(errors: Reorm::PropertyErrors.new)
    obj.define_singleton_method(:include?) {|key| obj.to_h.include?(key)}
    obj
  }
  let(:path) {
    "one -> two -> three".to_sym
  }

  it "sets no errors if the object passed to it does have a field value matching one of the included values" do
    object.one = {two: {three: 3}}
    subject.validate(object)
    expect(object.errors.clear?).to eq(true)
  end

  it "sets an error if the object passed in does not possess the field value" do
    subject.validate(object)
    expect(object.errors.clear?).to eq(false)
    expect(object.errors.properties).to include(path)
    expect(object.errors.messages(path)).to include("is not set to one of its permitted values.")
  end

  it "sets an error if the object passed in does not have a field value that matches one of the included values" do
    object.one = {two: {three: 2}}
    subject.validate(object)
    expect(object.errors.clear?).to eq(false)
    expect(object.errors.properties).to include(path)
    expect(object.errors.messages(path)).to include("is not set to one of its permitted values.")
  end
end
