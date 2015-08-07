#! /usr/bin/env ruby
# Copyright (c), 2015 Peter Wood
# See the license.txt for details of the licensing of the code in this file.

module Reorm
  class Validator
    def initialize(message, *field)
      @field   = FieldPath.new(*field)
      @message = message
    end
    attr_reader :field, :message
  end
end
