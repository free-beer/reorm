#! /usr/bin/env ruby
# Copyright (c), 2015 Peter Wood
# See the license.txt for details of the licensing of the code in this file.

module Reorm
  # A module that defines the class level data used for events.
  module EventData
    @@class_events = {}
  end

  module SpecifyEventHandlers
    include EventData

    def after_create(*methods)
      store_event_handlers(:after_create, *methods)
    end

    def after_save(*methods)
      store_event_handlers(:after_save, *methods)
    end

    def after_update(*methods)
      store_event_handlers(:after_update, *methods)
    end

    def after_validate(*methods)
      store_event_handlers(:after_validate, *methods)
    end

    def before_create(*methods)
      store_event_handlers(:before_create, *methods)
    end

    def before_save(*methods)
      store_event_handlers(:before_save, *methods)
    end

    def before_update(*methods)
      store_event_handlers(:before_update, *methods)
    end

    def before_validate(*methods)
      store_event_handlers(:before_validate, *methods)
    end

    def store_event_handlers(event, *methods)
      @@class_events[self] = {} if !@@class_events.include?(self)
      @@class_events[self][event] = [] if !@@class_events[self].include?(event)
      @@class_events[self][event] = @@class_events[self][event].concat(methods).uniq
    end
  end

  # A module that defines the class level methods for setting event handlers.
  module EventHandler
    include EventData

    def EventHandler.included(target)
      target.extend(SpecifyEventHandlers)
    end
  end

  # A module that is used to provide the methods the create events.
  module EventSource
    include EventData

    def fire_events(settings={})
      events = settings[:events]
      if events && !events.empty?
        object   = (settings[:target] ? settings[:target] : self)
        handlers = @@class_events[self.instance_of?(Class) ? self : self.class]
        if handlers && !handlers.empty?
          events.each do |event|
            if handlers.include?(event)
              handlers[event].each do |handler|
                if !object.respond_to?(handler, true)
                  raise Error, "Unable to locate a method called '#{handler}' for an instance of the #{object.class.name} class."
                end
                object.__send__(handler)
              end
            end
          end
        end
      end
    end

    def EventSource.included(target)
      target.extend(EventSource)
    end
  end
end
