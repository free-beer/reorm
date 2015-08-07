#! /usr/bin/env ruby
# Copyright (c), 2015 Peter Wood
# See the license.txt for details of the licensing of the code in this file.

require "active_support/inflector"
require "configurative"
require "connection_pool"
require "logjam"
require "rethinkdb"
require "stringio"
require "reorm/version"
require "reorm/exceptions"
require "reorm/configuration"
require "reorm/field_path"
require "reorm/modules"
require "reorm/validators"
require "reorm/model"
require "reorm/property_errors"
require "reorm/cursor"

include RethinkDB::Shortcuts

module Reorm
  # Constants used with Rethinkdb connections.
  DEFAULT_SIZE               = 5
  DEFAULT_TIMEOUT            = 5
  SETTINGS_NAMES             = [:host, :port, :db, :auth_key, :timeout]

  # Module property containing the connection pool.
  @@reorm_connections = ConnectionPool.new(size:    Configuration.fetch(:size, DEFAULT_SIZE),
                                             timeout: Configuration.fetch(:timeout, DEFAULT_TIMEOUT)) do
                            settings = Configuration.instance.to_h.inject({}) do |store, entry|
                                         store[entry[0]] = entry[1] if SETTINGS_NAMES.include?(entry[0])
                                         store
                                       end
                            r.connect(settings)
                          end

  # A method for obtaining a connection from the module connection pool. The
  # intended usage is that you call this method with a block that will be passed
  # the connection as a parameter.
  def self.connection
    @@reorm_connections.with do |connection|
      yield connection
    end
  end
end
