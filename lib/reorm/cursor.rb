#! /usr/bin/env ruby
# Copyright (c), 2015 Peter Wood
# See the license.txt for details of the licensing of the code in this file.

module Reorm
  class Cursor
    def initialize(model_class, query, order_by=nil)
      @model_class = model_class
      @query       = query
      @cursor      = nil
      @offset      = 0
      @total       = 0
      @order_by    = order_by
    end
    attr_reader :model_class

    def close
      @cursor.close if @cursor && !@cursor.kind_of?(Array)
      @cursor = nil
      @offset = @total = 0
      self
    end
    alias :reset :close

    def filter(predicate)
      Cursor.new(model_class, @query.filter(predicate), @order_by)
    end

    def count
      Reorm.connection do |connection|
        @query.count.run(connection)
      end
    end

    def exhausted?
      open? && @offset == @total
    end

    def find
      model = nil
      each do |record|
        found = yield(record)
        if found
          model = record
          break
        end
      end
      model
    end
    alias :detect :find

    def next
      open if !open?
      if exhausted?
        raise Error, "There are no more matching records."
      end
      data    = @order_by.nil? ? @cursor.next : @cursor[@offset]
      @offset += 1
      model_class.new(data)
    end

    def each(&block)
      @order_by.nil? ? each_without_order_by(&block) : each_with_order_by(&block)
    end

    def inject(token=nil)
      each do |record|
        yield token, record
      end
      token
    end

    def nth(offset)
      model = nil
      if offset >= 0 && offset < count
        Reorm.connection do |connection|
          model = model_class.new(@query.nth(offset).run(connection))
        end
      end
      model
    end

    def first
      nth(0)
    end

    def last
      nth(count - 1)
    end

    def to_a
      inject([]) {|list, record| list << record}
    end

    def limit(size)
      Cursor.new(model_class, @query.limit(size), @order_by)
    end

    def offset(index)
      Cursor.new(model_class, @query.skip(quantity), @order_by)
    end
    alias :skip :offset

    def slice(start_at, end_at=nil, left_bound='closed', right_bound="open")
      if end_at
        Cursor.new(model_class, @query.slice(start_at, end_at, left_bound, right_bound), @order_by)
      else
        Cursor.new(model_class, @query.slice(start_at), @order_by)
      end
    end

    def order_by(*arguments)
      Cursor.new(model_class, @query, arguments)
    end

  private

    def open
      Reorm.connection do |connection|
        array_based = false
        if @order_by && @order_by.size > 0
          clause = @order_by.find {|entry| entry.kind_of?(Hash)}
          array_based = clause.nil? || clause.keys != [:index]
        end

        @offset = 0
        if !array_based
          @total  = @query.count.run(connection)
          @cursor = @query.run(connection)
        else
          @cursor = @query.order_by(*@order_by).run(connection)
          @total  = @cursor.size
        end
      end
    end

    def open?
      !@cursor.nil?
    end

    def each_with_order_by
      Reorm.connection do |connection|
        @query.order_by(*@order_by).run(connection).each do |record|
          yield model_class.new(record)
        end
      end
    end

    def each_without_order_by
      Reorm.connection do |connection|
        cursor = @query.run(connection)
        begin
          cursor.each do |record|
            yield model_class.new(record)
          end
        ensure
          cursor.close
        end
      end
    end
  end
end
