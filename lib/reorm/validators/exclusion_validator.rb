#! /usr/bin/env ruby
# Copyright (c), 2015 Peter Wood
# See the license.txt for details of the licensing of the code in this file.

module Reorm
  class ExclusionValidator < Validator
    def initialize(values, *field)
      super("is set to an unpermitted value.", *field)
      @values = [].concat(values)
    end

    def validate(object)
      if @values.include?(field.value(object))
        object.errors.add(field.to_s, message)
      end
    end
  end
end
