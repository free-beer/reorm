#! /usr/bin/env ruby
# Copyright (c), 2015 Peter Wood
# See the license.txt for details of the licensing of the code in this file.

module Reorm
	class Error < StandardError
		def initialize(message, cause=nil)
			super(message)
			@cause = cause
		end
		attr_reader :cause
	end
end
