require "spec_helper"

class CursorTestModel < Reorm::Model
end

describe Reorm::Cursor do
  subject {
    Reorm::Cursor.new(CursorTestModel, r.table(CursorTestModel.table_name))
  }

  before do
    CursorTestModel.create(index: 1)
    CursorTestModel.create(index: 2)
    CursorTestModel.create(index: 3)
    CursorTestModel.create(index: 4)
    CursorTestModel.create(index: 5)
  end

  describe "#close" do
    it "silently does nothing if the internal cursor isn't open" do
      expect {
        subject.close
      }.not_to raise_exception
    end

    it "cleans up where the internal cursor is open" do
      expect(subject.next).not_to be_nil
      expect {
        subject.close
      }.not_to raise_exception
    end
  end

  describe "#count()" do
    it "returns a count of the number of rows that the cursor will iterate across" do
      expect(subject.count).to eq(5)
    end
  end

  describe "#exhausted?()" do
    it "returns false if the internal cursor isn't open" do
      expect(subject.exhausted?).to eq(false)
    end

    it "returns false if the internal cursor is open but there are rows remaining" do
      expect(subject.next).not_to be_nil
      expect(subject.exhausted?).to eq(false)
    end

    it "returns true if the internal cursor is open and there are no more rows remaining" do
      subject.count.times {expect(subject.next).not_to be_nil}
      expect(subject.exhausted?).to eq(true)
    end
  end

  describe "#find()" do
    it "returns the first row that matches the search block" do
      model = subject.find {|record| record.index == 3}
      expect(model).not_to be_nil
      expect(model.class).to eq(CursorTestModel)
    end

    it "returns nil if a matching record cannot be found" do
      model = subject.find {|record| record.index == 3000}
      expect(model).to be_nil
    end
  end

  describe "#next()" do
    describe "when used without an order by clause" do
      it "returns the next record from the cursor" do
        (1..5).each do |index|
          model = subject.next
          expect(model).not_to be_nil
          expect((1..5)).to include(model.index)
        end
      end

      it "raises an exception if called on an exhausted cursor" do
        5.times {subject.next}
        expect {
          subject.next
        }.to raise_exception(Reorm::Error, "There are no more matching records.")
      end
    end

    describe "when used with an order by clause" do
      subject {
        Reorm::Cursor.new(CursorTestModel, r.table(CursorTestModel.table_name)).order_by(:index)
      }

      it "returns the next record from the cursor" do
        (1..5).each do |index|
          model = subject.next
          expect(model).not_to be_nil
          expect((1..5)).to include(model.index)
        end
      end

      it "raises an exception if called on an exhausted cursor" do
        5.times {subject.next}
        expect {
          subject.next
        }.to raise_exception(Reorm::Error, "There are no more matching records.")
      end
    end
  end

  describe "#each()" do
    describe "when an order by clause hasn't been applied" do
      it "yields each available record to the specified block" do
        indices = [1, 2, 3, 4, 5]
        subject.each do |record|
          indices.delete(record.index)
        end
        expect(indices.empty?).to eq(true)
      end
    end

    describe "when an order by clause has been applied" do
      subject {
        Reorm::Cursor.new(CursorTestModel, r.table(CursorTestModel.table_name)).order_by(:index)
      }

      it "yields each available record to the specified block" do
        indices = [1, 2, 3, 4, 5]
        subject.each do |record|
          indices.delete(record.index)
        end
        expect(indices.empty?).to eq(true)
      end
    end
  end

  describe "#inject()" do
    it "yields each available record to the specified block" do
      output = subject.inject([]) {|list, record| list << record.index}
      expect(output).to include(1)
      expect(output).to include(2)
      expect(output).to include(3)
      expect(output).to include(4)
      expect(output).to include(5)
    end
  end

  describe "#nth()" do
    it "returns the record at the specified offset" do
      expect(subject.nth(2).index).to eq(subject.to_a[2].index)
    end

    it "returns nil if an invalid offset is specified" do
      expect(subject.nth(1000)).to be_nil
      expect(subject.nth(-1)).to be_nil
    end
  end

  describe "#first()" do
    let(:first) {
      subject.nth(0)
    }

    it "returns the first matching record from the cursor" do
      expect(subject.first.index).to eq(first.index)
    end
  end

  describe "#last()" do
    let(:last) {
      subject.nth(4)
    }

    it "returns the last matching record from the cursor" do
      expect(subject.last.index).to eq(last.index)
    end
  end

  describe "#to_a()" do
    it "returns an array containing all of the matching records from the cursor" do
      array = subject.to_a
      expect(array).not_to be_nil
      expect(array.class).to eq(Array)
      expect(array.size).to eq(5)
      expect(array.inject([]) {|list, model| list << model.index}.sort).to eq([1, 2, 3, 4, 5])
    end
  end

  describe "#filter()" do
    it "returns a Cursor object" do
      output = subject.filter({index: 4})
      expect(output).not_to be_nil
      expect(output.class).to eq(Reorm::Cursor)
    end

    it "applies a filter to the cursor records" do
      cursor = subject.filter({index: 4})
      expect(cursor.count).to eq(1)
      expect(cursor.first.index).to eq(4)
    end
  end

  describe "#order_by()" do
    it "returns a Cursor object" do
      output = subject.order_by(:index)
      expect(output).not_to be_nil
      expect(output.class).to eq(Reorm::Cursor)
    end

    it "applies an ordering to the cursor records" do
      cursor  = subject.order_by(r.desc(:index))
      indices = cursor.inject([]) {|list, record| list << record.index}
      expect(indices).to eq([5, 4, 3, 2, 1])
    end
  end

  describe "#delete()" do
    it "deletes all records" do
      query = CursorTestModel.filter do |record|
        (record["index"].eq(1) | record["index"].eq(3) | record["index"].eq(5))
      end
      query.delete
      expect(CursorTestModel.all.count).to eq(2)
    end    
  end

  describe "#offset()" do
    it "moves the starting point for records retrieved" do
      expect(subject.count).to eq(5)
      expect(subject.offset(2).count).to eq(3)
    end
  end

  describe "#limit()" do
    it "restricts the number of records to be retrieved" do
      expect(subject.count).to eq(5)
      expect(subject.limit(2).count).to eq(2)
    end
  end
end
