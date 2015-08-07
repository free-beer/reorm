#! /usr/bin/env ruby
# Copyright (c), 2015 Peter Wood
# See the license.txt for details of the licensing of the code in this file.

module Reorm
  class MinimumLengthValidator < Validator
    def initialize(length, *field)
      super("is too short (minimum length is #{length} characters).", *field)
      @length = length
    end

    def validate(object)
      value = field.value(object)
      if [nil, ""].include?(value) || value.to_s.length < @length
        object.errors.add field.to_s, message
      end
    end
  end
end
