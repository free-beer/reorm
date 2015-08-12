#! /usr/bin/env ruby
# Copyright (c), 2015 Peter Wood
# See the license.txt for details of the licensing of the code in this file.

module Reorm
  class Model
    include EventSource
    include EventHandler
    include TableBacked
    include Validations

    @@class_tables = {}

    def initialize(properties={})
      @properties = {}
      properties.each do |key, value|
        if self.respond_to?(setter_name(key))
          self.send(setter_name(key), value)
        else
          @properties[key.to_sym] = value
        end
      end
      @errors     = PropertyErrors.new
    end
    attr_reader :errors

    def valid?
      validate
      @errors.clear?
    end

    def validate
      fire_events(events: [:before_validate])
      @errors.reset
      fire_events(events: [:after_validate])
      self
    end

    def include?(field)
      @properties.include?(property_name(field))
    end

    def save(validated=true)
      if validated && !valid?
        raise Error, "Validation error encountered saving an instance of the #{self.class.name} class."
      end

      action_type = (@properties[primary_key] ? :update : :create)
      if action_type == :create
        fire_events(events: [:before_create, :before_save])
      else
        fire_events(events: [:before_update, :before_save])
      end

      Reorm.connection do |connection|
        ensure_table_exists(connection)
        if !@properties.include?(primary_key)
          result = r.table(table_name).insert(self.to_h, return_changes: true).run(connection)
          if !result["inserted"] || result["inserted"] != 1
            raise Error, "Creation of database record for an instance of the #{self.class.name} class failed."
          end
          @properties[primary_key] = result["generated_keys"].first
        else
          result = r.table(table_name).update(self.to_h).run(connection)
          if !result["replaced"] || !result["replaced"] == 1
            raise Error, "Update of database record for an instance of the #{self.class.name} class failed."
          end
        end
      end

      if action_type == :create
        fire_events(events: [:after_save, :after_create])
      else
        fire_events(events: [:after_save, :after_update])
      end
      self
    end

    def update(properties={})
      properties.each do |field, value|
        self.__send__(setter_name(field), value)
      end
      self.save if !properties.empty?
      self
    end

    def [](property_name)
      @properties[property_name.to_sym]
    end

    def []=(property_name, value)
      @properties[property_name.to_sym] = value
      value
    end

    def respond_to?(method_name, include_private=false)
      method_name.to_s[-1, 1] == "=" || @properties.include?(property_name(method_name)) || super
    end

    def method_missing(method_name, *arguments, &block)
      if method_name.to_s[-1,1] != "="
        if @properties.include?(property_name(method_name))
          @properties[method_name]
        else
          super
        end
      else
        @properties[property_name(method_name)] = arguments.first
      end
    end

    def to_h
      {}.merge(@properties)
    end

    def self.create(properties={})
      object = self.new(properties)
      object.save
      object
    end

    def self.all
      Cursor.new(self, r.table(table_name))
    end

    def self.filter(predicate=nil, &block)
      if predicate.nil?
        Cursor.new(self, r.table(table_name).filter(&block))
      else
        Cursor.new(self, r.table(table_name).filter(predicate))
      end
    end

  private

    def property_name(name)
      name.to_s[-1,1] == "=" ? name.to_s[0...-1].to_sym : name
    end

    def setter_name(name)
      "#{name}=".to_sym
    end

    def ensure_table_exists(connection)
      tables = r.table_list.run(connection)
      if !tables.include?(table_name)
        r.table_create(table_name, primary_key: primary_key).run(connection)
      end
    end
  end
end
