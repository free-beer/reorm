#! /usr/bin/env ruby
# Copyright (c), 2015 Peter Wood
# See the license.txt for details of the licensing of the code in this file.

module Reorm
  module Validations
    def validate_presence_of(field)
      PresenceValidator.new(*field).validate(self)
    end

    def validate_length_of(field, options={})
      if options.include?(:minimum)
        MinimumLengthValidator.new(options[:minimum], *field).validate(self)
      end

      if options.include?(:maximum)
        MaximumLengthValidator.new(options[:maximum], *field).validate(self)
      end
    end

    def validate_inclusion_of(field, *values)
      InclusionValidator.new(values, *field).validate(self)
    end

    def validate_exclusion_of(field, *values)
      ExclusionValidator.new(values, *field).validate(self)
    end
  end
end
