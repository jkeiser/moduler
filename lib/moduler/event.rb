module Moduler
  #
  # An Event can be listened to by multiple listeners, and when it fires, all
  # listeners' procs are called.
  #
  class Event
    #
    # Create a new Event.
    #
    # ==== Arguments
    # [name]
    # A name for the event, for errors and printing
    # [options]
    # A list of symbols and/or a hash of options.
    # - +:single_event+ - only one event will ever be fired.  Clean up after that.
    # - +:unregister_on+ => <event> - after the given event is fired, clean up.
    #
    def initialize(name, *options)
      @name = name
      @listeners = []
      @options = {}
      options.each do |option|
        if option.is_a?(Hash)
          @options.merge!(option)
        else
          @options[option] = true
        end
      end
      if @options.has_key?(:unregister_on)
        @options[:unregister_on].register { unregister_all }
      end
    end

    #
    # The name of the event, for printing
    #
    attr_reader :name

    #
    # The options passed to +new+, in hash form.
    #
    attr_reader :options

    #
    # The event listeners
    #
    attr_reader :listeners

    #
    # Fire this event.  Calls all listeners with the given arguments.
    #
    def fire(*args)
      listeners.each do |listener|
        listener.call(*args)
      end
      if options[:single_event]
        unregister_all
      end
    end

    #
    # Fire this event.  Calls all listeners in the context of the given DSL,
    # with the given arguments.
    #
    def fire_in_context(context, *args)
      listeners.each do |listener|
        context.instance_exec(*args, &listener)
      end
    end

    #
    # Register a new listener.  If both a listener and a block are passed,
    # the listener is registered, the block is run, and then the listener is
    # unregistered before +register+ returns.
    #
    def register(listener=nil, &block)
      if listener
        listeners << listener
        if block
          begin
            yield
          ensure
            unregister(listener)
          end
        end
        listener
      else
        listeners << block
        block
      end
    end

    #
    # Unregister all listeners.
    #
    def unregister_all
      listeners.clear
    end

    #
    # Unregister a specific listener.
    #
    def unregister(listener)
      listeners.delete(listener)
    end
  end
end
