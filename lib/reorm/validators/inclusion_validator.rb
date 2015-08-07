#! /usr/bin/env ruby
# Copyright (c), 2015 Peter Wood
# See the license.txt for details of the licensing of the code in this file.

module Reorm
  class InclusionValidator < Validator
    def initialize(values, *field)
      super("is not set to one of its permitted values.", *field)
      @values = values
    end

    def validate(object)
      if !@values.include?(field.value(object))
        object.errors.add(field.to_s, message)
      end
    end
  end
end
