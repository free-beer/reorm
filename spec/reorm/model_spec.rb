require "spec_helper"

class ValidationTestModel < Reorm::Model
	before_validate :called
	after_validate :called

	def initialize(setting=nil)
		super(blah: setting)
		@calls = 0
	end
	attr_reader :calls

	def called
		@calls += 1
	end

	def validate
		super
		errors.add(:blah, "has not been set") if [nil, ""].include?(blah)
	end
end

class SaveTestModel < Reorm::Model
	after_create :on_after_create
  after_delete :on_after_delete
	after_save :on_after_save
	after_update :on_after_update
	before_create :on_before_create
  before_delete :on_before_delete
	before_save :on_before_save
	before_update :on_before_update

	def initialize(properties={})
		super(properties)
		@events = []
	end
	attr_reader :events

	def reset_events
		@events = []
	end

	def on_after_create
		@events << :after_create
	end

  def on_after_delete
    @events << :after_delete
  end

	def on_after_save
		@events << :after_save
	end

	def on_after_update
		@events << :after_update
	end

	def on_before_create
		@events << :before_create
	end

  def on_before_delete
    @events << :before_delete
  end

	def on_before_save
		@events << :before_save
	end

	def on_before_update
		@events << :before_update
	end
end

class SetterTestModel < Reorm::Model
  def initialize(properties={})
    super
  end
  attr_reader :called

  def value=(setting)
    @called = true
    self[:value] = setting
  end
end

describe Reorm::Model do
  describe "#initialize()" do
    it "invokes an explicit property setter if one is defined" do
      object = SetterTestModel.new(value: 234)
      expect(object.called).to eq(true)
      expect(object.value).to eq(234)
    end
  end

  describe "model properties" do
    subject {
      SetterTestModel.new(existing_value: 1234)
    }

    it "makes top level values available as model properties" do
      expect(subject[:existing_value]).to eq(1234)
      expect(subject.existing_value).to eq(1234)
    end

    describe "assignment of a previously non-existent property" do
      it "assigns the property the specified value" do
        subject.new_value = "Text."
        expect(subject[:new_value]).to eq("Text.")
        expect(subject.new_value).to eq("Text.")
      end
    end

    describe "assignment of an existing property" do
      it "updates the values setting" do
        subject.existing_value = "Changed!"
        expect(subject[:existing_value]).to eq("Changed!")
        expect(subject.existing_value).to eq("Changed!")
      end
    end
  end

	describe "#valid?()" do
		subject {
			ValidationTestModel.new
		}

		it "returns true if the an object does not fail validation" do
			subject.blah = 1
			expect(subject.valid?).to eq(true)
		end

		it "returns false if an object fails validation" do
			expect(subject.valid?).to eq(false)
		end
	end

	describe "#validate" do
		subject {
			ValidationTestModel.new
		}

		it "resets the list of errors for an object" do
			expect(subject.valid?).to eq(false)
			expect(subject.errors.clear?).to eq(false)
			subject.blah = 123
			subject.validate
			expect(subject.errors.clear?).to eq(true)
		end

		it "fires a before and after validation events when called" do
			subject.validate
			expect(subject.calls).to eq(2)
		end
	end

	describe "#save()" do
		describe "for a previously unsaved object" do
			subject {
				SaveTestModel.new(one: 1, two: 2, three: 3)
			}

			it "creates a record when called on a valid object" do
				subject.save
				expect(subject.id).not_to be_nil
				record = nil
				Reorm.connection do |connection|
					record = r.table(subject.table_name).get(subject.id).run(connection)
				end
				expect(record).not_to be_nil
				expect(record["id"]).to eq(subject.id)
				expect(record["one"]).to eq(subject.one)
				expect(record["two"]).to eq(subject.two)
				expect(record["three"]).to eq(subject.three)
			end

			it "fires the before create, before save, after save and after create events" do
				subject.save
				expect(subject.events).to eq([:before_create, :before_save, :after_save, :after_create])
			end

			it "raises an exception if the object is invalid and validation is required" do
				expect {
					ValidationTestModel.new(nil).save
				}.to raise_exception(Reorm::Error, "Validation error encountered saving an instance of the ValidationTestModel class.")
			end

			it "does not raises an exception if the object is invalid but validation is off" do
				expect {
					ValidationTestModel.new(nil).save(false)
				}.not_to raise_exception
			end
		end

		describe "for a previously saved object" do
			subject {
				SaveTestModel.new(one: 1, two: 2, three: 3)
			}

			before do
				subject.save
				subject.reset_events
			end

			it "updates the objects record when called on a valid object" do
				subject.two = "TWO"
				subject.save
				record = nil
				Reorm.connection do |connection|
					record = r.table(subject.table_name).get(subject.id).run(connection)
				end
				expect(record).not_to be_nil
				expect(record["id"]).to eq(subject.id)
				expect(record["one"]).to eq(subject.one)
				expect(record["two"]).to eq(subject.two)
				expect(record["three"]).to eq(subject.three)
			end

			it "fires the before update, before save, after save and after update events" do
				subject.save
				expect(subject.events).to eq([:before_update, :before_save, :after_save, :after_update])
			end

			it "raises an exception if the object is invalid and validation is required" do
				model = ValidationTestModel.new(1)
				model.save
				model.blah = nil
				expect {
					model.save
				}.to raise_exception(Reorm::Error, "Validation error encountered saving an instance of the ValidationTestModel class.")
			end

			it "does not raises an exception if the object is invalid but validation is off" do
				model = ValidationTestModel.new(1)
				model.save
				model.blah = nil
				expect {
					model.save(false)
				}.not_to raise_exception
			end
		end
	end

	describe "#update()" do
		subject {
			SaveTestModel.new(one: 1, two: 2, three: 3)
		}

		it "updates the properties for the model object and calls save()" do
			expect(subject).to receive(:save)
		  subject.update(one: "One", four: 4)
		  expect(subject.one).to eq("One")
		  expect(subject.two).to eq(2)
		  expect(subject.three).to eq(3)
		  expect(subject.four).to eq(4)
		end

		it "does not calls save if the no properties are specified" do
			expect(subject).not_to receive(:save)
		  subject.update()
		end
	end

  describe "#delete()" do
    subject {
      SaveTestModel.create(one: 1, two: 2, three: 3)
    }

    it "removes the record for the model instance deleted" do
      id = subject.id
      subject.delete
      expect(subject.id).to be_nil
      expect(SaveTestModel.filter(id: id).count).to eq(0)
    end

    it "does nothing if the model instance has not been saved" do
      instance = SaveTestModel.new(one: 1, two: 2, three: 3)
      expect {
        instance.delete
      }.not_to raise_exception
      subject
      expect(SaveTestModel.all.count).to eq(1)
    end

    it "fires the before and after delete events" do
      instance = SaveTestModel.create(one: 1, two: 2)
      instance.delete
      expect(instance.events).to include(:before_delete)
      expect(instance.events).to include(:after_delete)
    end
  end

	describe "#[]()" do
		subject {
			SaveTestModel.new(one: 1, two: "Two")
		}

		it "returns the value of the named property if it exists" do
			expect(subject[:one]).to eq(1)
			expect(subject[:two]).to eq("Two")
		end

		it "returns nil if the named property does not exist" do
			expect(subject[:blah]).to be_nil
		end
	end

	describe "#[]=()" do
		subject {
			SaveTestModel.new(one: 1, two: "Two")
		}

    it "assigns the property value if it does not exist" do
			subject[:three] = 3
			expect(subject.three).to eq(3)
		end

		it "updates the property value if it does exist" do
			subject[:one] = "One"
			expect(subject[:one]).to eq("One")
		end
	end

	describe "#has_property?()" do
		subject {
			SaveTestModel.new(one: 1, two: "Two")
		}

    it "returns true when a model possesses the named property" do
    	expect(subject.has_property?(:two)).to eq(true)
    end

    it "returns false when a model does not possess the named property" do
    	expect(subject.has_property?(:three)).to eq(false)
    end
	end

	describe "#get_property()" do
		subject {
			SaveTestModel.new(one: 1, two: "Two")
		}

    it "returns the value of the specified property" do
    	expect(subject.get_property(:one)).to eq(1)
    	expect(subject.get_property(:two)).to eq("Two")
    end

    it "returns nil of a property does not exist" do
    	expect(subject.get_property(:three)).to be_nil
    end
	end

	describe "#set_property()" do
		subject {
			SaveTestModel.new(one: 1, two: "Two")
		}

    it "updates the value of an existing property" do
    	subject.set_property(:two, 2)
    	expect(subject.two).to eq(2)
    end

    it "assigns a value to a property that did not previously exist" do
    	subject.set_property(:three, 3)
    	expect(subject.three).to eq(3)
    end
	end

  describe "#set_proerties()" do
    subject {
      SaveTestModel.new(one: 1, two: "Two", three: 3)
    }

    it "updates existing properties" do
      subject.set_properties(one: "One", two: 2, three: "Three")
      expect(subject.one).to eq("One")
      expect(subject.two).to eq(2)
      expect(subject.three).to eq("Three")
    end

    it "assigns properties that had not been previously set" do
      subject.set_properties(four: 4, five: "Five")
      expect(subject.one).to eq(1)
      expect(subject.two).to eq("Two")
      expect(subject.three).to eq(3)
      expect(subject.four).to eq(4)
      expect(subject.five).to eq("Five")
    end
  end

  describe "#assign_properties()" do
    subject {
      SetterTestModel.new
    }

    it "assigns model properties but bypasses explicit assignment methods" do
      subject.assign_properties(value: "Value.")
      expect(subject.value).to eq("Value.")
      expect(subject.called).to be_nil
    end
  end

  describe "#get()" do
    let(:model) {
      SaveTestModel.create(one: 1)
    }

    it "returns a model instance that matches the key if one exists" do
      object = SaveTestModel.get(model.id)
      expect(object).not_to be_nil
      expect(object.id).to eq(model.id)
      expect(object.one).to eq(1)
    end

    it "returns nil if a match record could not be found" do
      expect(SaveTestModel.get(SecureRandom.uuid)).to be_nil
    end
  end

	describe "#create()" do
		let(:standin) {
			SaveTestModel.new
		}

		it "creates and saves an instance of the specified class" do
			expect(standin).to receive(:save)
			expect(SaveTestModel).to receive(:new).and_return(standin)
			expect(SaveTestModel.create).to eq(standin)
		end
	end

	describe "#all()" do
		before do
			SaveTestModel.create(one: 1, two: 2)
			SaveTestModel.create(one: 3, two: 4)
			SaveTestModel.create(one: 5, two: 6)
		end

		subject {
			SaveTestModel
		}

		it "returns a cursor for the model records" do
			cursor = subject.all
			expect(cursor).not_to be_nil
			expect(cursor.class).to eq(Reorm::Cursor)
			expect(cursor.inject([]) {|list, entry| list << entry.one}.sort).to eq([1,3,5])
		end
	end

	describe "#filter()" do
		before do
			SaveTestModel.create(one: 1, two: 2)
			SaveTestModel.create(one: 3, two: 4)
			SaveTestModel.create(one: 5, two: 6)
		end

		subject {
			SaveTestModel
		}

		it "returns a cursor for the model records" do
			cursor = subject.filter(two: 4)
			expect(cursor).not_to be_nil
			expect(cursor.class).to eq(Reorm::Cursor)
			expect(cursor.inject([]) {|list, entry| list << entry.one}.sort).to eq([3])
		end
	end
end
