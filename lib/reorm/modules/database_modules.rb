#! /usr/bin/env ruby
# Copyright (c), 2015 Peter Wood
# See the license.txt for details of the licensing of the code in this file.

module Reorm
  module ClassDatabaseSettings
    @@class_db_settings = {}

    def assign_table_defaults
      @@class_db_settings[self] = {primary_key: :id,
                                   table_name:  self.name.split("::").last.tableize}
    end

    def table_settings
      assign_table_defaults if !@@class_db_settings.include?(self)
      @@class_db_settings[self]
    end
  end

  module PrimaryKeyedClassMethods
    def primary_key(field=nil)
      table_settings[:primary_key] = field if !field.nil?
      table_settings[:primary_key]
    end

    def table_name(name=nil)
      table_settings[:table_name] = name if !name.nil?
      table_settings[:table_name]
    end
  end

  module PrimaryKeyedInstanceMethods
    def primary_key
      self.class.primary_key
    end

    def table_name
      self.class.table_name
    end
  end

  # A module that defines the data and methods for a class that is backed on to
  # a database table.
  module TableBacked
    def TableBacked.included(target)
      target.extend(ClassDatabaseSettings)
      target.extend(PrimaryKeyedClassMethods)
      target.include(PrimaryKeyedInstanceMethods)
    end
  end

  module Timestamped
    def set_created_at
      self.created_at = Time.now
      self.updated_at = nil
    end

    def set_updated_at
      self.updated_at = Time.now
    end

    def Timestamped.included(target)
      target.before_create :set_created_at
      target.before_update :set_updated_at
    end
  end
end
