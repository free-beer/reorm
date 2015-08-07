#! /usr/bin/env ruby
# Copyright (c), 2015 Peter Wood
# See the license.txt for details of the licensing of the code in this file.

module Reorm
	class PropertyErrors
		def initialize
			@errors = {}
		end

		def clear?
			@errors.empty?
		end

		def reset
			@errors = {}
		end

		def include?(property)
			@errors.include?(property.to_sym)
		end

		def add(property, message)
			if ![nil, ""].include?(message)
				@errors[property.to_sym] = [] if !@errors.include?(property.to_sym)
				@errors[property.to_sym] << message
			end
			self
		end

    def properties
			@errors.keys
		end

		def messages(property)
			[].concat(@errors.fetch(property.to_sym, []))
		end

		def each
			@errors.each {|property, messages| yield(property, messages)}
		end

		def to_s
			text = StringIO.new
			@errors.each do |property, messages|
				messages.each do |message|
					text << "#{text.size > 0 ? "\n" : ""}#{property} #{message}"
				end
			end
			text.string
		end
	end
end
