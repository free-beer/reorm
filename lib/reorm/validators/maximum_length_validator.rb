#! /usr/bin/env ruby
# Copyright (c), 2015 Peter Wood
# See the license.txt for details of the licensing of the code in this file.

module Reorm
  class MaximumLengthValidator < Validator
    def initialize(length, *field)
      super("is too long (maximum length is #{length} characters).", *field)
      @length = length
    end

    def validate(object)
      value = field.value(object)
      if value && value.to_s.length > @length
        object.errors.add field.to_s, message
      end
    end
  end
end
