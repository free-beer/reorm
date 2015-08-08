#! /usr/bin/env ruby
# Copyright (c), 2015 Peter Wood
# See the license.txt for details of the licensing of the code in this file.

module Reorm
  class FieldPath
    def initialize(*path)
      @path = [].concat(path)
    end

    def name
      @path.last
    end

    def value(document)
      locate(document).first
    end

    def value!(document)
      result = locate(document)
      raise Error, "Unable to locate the #{name} (full path: #{self}) field for an instance of the #{document.class.name} class." if !result[1]
      result[0]
    end

    def exists?(document)
      locate(document)[1]
    end

    def to_s
      @path.join(" -> ")
    end

  private

    def locate(document)
      result = [nil, false]
      value = document
      @path.each_with_index do |field, index|
        if !value || !value.respond_to?(:include?) || !value.include?(field)
          value = nil
          break
        else
          if index == @path.length - 1
            result = [value_from_object(field, value), true]
          else
            value = value_from_object(field, value)
          end
        end
      end
      result
    end

    def value_from_object(value, object)
      if object.respond_to?(value)
        object.send(value)
      else
        object[value]
      end
    end
  end
end
