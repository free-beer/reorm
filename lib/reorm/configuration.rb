#! /usr/bin/env ruby
# Copyright (c), 2015 Peter Wood
# See the license.txt for details of the licensing of the code in this file.

module Reorm
	class Configuration < Configurative::Settings
		files *(Dir.glob(File.join(Dir.getwd, "**", "database.{yml,yaml,json}")) +
		        Dir.glob(File.join(Dir.getwd, "**", "rethinkdb.{yml,yaml,json}")) +
				 	  Dir.glob(File.join(Dir.getwd, "**", "application.{yml,yaml,json}")))
		#section "rethinkdb"
	end
end
