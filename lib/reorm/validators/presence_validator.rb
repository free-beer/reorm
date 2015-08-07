#! /usr/bin/env ruby
# Copyright (c), 2015 Peter Wood
# See the license.txt for details of the licensing of the code in this file.

module Reorm
  class PresenceValidator < Validator
    def initialize(*field)
      super("cannot be blank.", *field)
    end

    def validate(object)
      if !field.exists?(object) || [nil, ""].include?(field.value(object))
        object.errors.add(field.to_s, message)
      end
    end
  end
end
