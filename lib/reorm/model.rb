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
      @errors     = PropertyErrors.new
      properties.each {|key, value| set_property(key, value)}
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
      properties.each do |property, value|
        set_property(property, value)
      end
      self.save if !properties.empty?
      self
    end

    def delete
      key = get_property(primary_key)
      if key
        Reorm.connection do |connection|
          fire_events(events: [:before_delete])
          result = r.table(table_name).get(key).delete.run(connection)
          if result["deleted"] != 1
            raise Error, "Deletion of record for a #{self.class.name} class instance with a primary key of #{key} failed."
          end
          fire_events(events: [:after_delete])
          set_property(primary_key, nil)
        end
      end
      self
    end

    def [](property_name)
      @properties[property_name.to_sym]
    end

    def []=(property_name, value)
      @properties[property_name.to_sym] = value
      value
    end

    def has_property?(property)
      @properties.include?(property_name(property))
    end

    def get_property(property)
      has_property?(property) ? self.__send__(property_name(property)) : nil
    end

    def set_property(property, value)
      self.__send__(setter_name(property), value)
      self
    end

    def set_properties(settings={})
      settings.each do |property, value|
        set_property(property, value)
      end
      self
    end

    def assign_properties(properties={})
      properties.each do |key, value|
        @properties[key.to_sym] = value
      end
      self
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

    def self.get(id)
      model = nil
      Reorm.connection do |connection|
        if table_exists?(table_name, connection)
          properties = r.table(table_name).get(id).run(connection)
          if !properties.nil?
            model = self.new
            model.assign_properties(properties)
          end
        end
      end
      model
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
      if !table_exists?(table_name, connection)
        r.table_create(table_name, primary_key: primary_key).run(connection)
      end
    end

    def table_exists?(name, connection)
      Model.table_exists?(name, connection)
    end

    def self.table_exists?(name, connection)
      r.table_list.run(connection).include?(name)
    end
  end
end
