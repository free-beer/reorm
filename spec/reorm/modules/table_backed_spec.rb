require "spec_helper"

class TableBackedClass
  include Reorm::TableBacked
end

describe TableBackedClass do
  describe "class level methods" do
    class TableBackedClass1
      include Reorm::TableBacked
      table_name "my_table_1"
      primary_key :other
    end

    subject {
      TableBackedClass1
    }

    it "allows the table name to be set and retrieved at the class level" do
      expect(subject.table_name).to eq("my_table_1")
    end

    it "allows the primary key to be set and retrieved at the class leve" do
      expect(subject.primary_key).to eq(:other)
    end
  end

  describe "instance level methods" do
    class TableBackedClass2
      include Reorm::TableBacked
    end

    subject {
      TableBackedClass2.new
    }

    it "allows the table name to be retrieved at the instance level" do
      expect(subject.table_name).to eq("table_backed_class2s")
    end

    it "allows the primary key to be set and retrieved at the instance level" do
      instance = TableBackedClass.new
      expect(subject.primary_key).to eq(:id)
    end
  end
end
