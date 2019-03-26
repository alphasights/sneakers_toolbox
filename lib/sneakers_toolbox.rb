require "sneakers_toolbox/version"
require 'sneakers_toolbox/lost_db_connection_handler'
require 'sneakers_toolbox/ticktock_worker'
require 'dry-configurable'

module SneakersToolbox
  extend Dry::Configurable
  setting :ticktock do
    # Allows to define callbacks for various exception classes for all Ticktock
    # workers in one place
    #
    # To be assigned a Hash where key is subclass of StandardError and value is
    # callable (its #call method will be called)
    #
    # Example use:
    #
    # SneakersToolbox.config.ticktock.error_callbacks = { MyError => Proc.new { notify_my_service } }
    setting(:error_callbacks, {}) do |callbacks|
      if callbacks.keys.all? { |k| k <= StandardError } && callbacks.values.all? { |v| v.respond_to?(:call) }
        callbacks
      else
        raise ArgumentError, "error callbacks must have error as key and object with #call as value"
      end
    end

    # Configure an object to be called after processing each message on every Ticktock worker
    #
    # This can be useful for notifying or pinging external services about the health of workers
    # Example:
    #
    # SneakersToolbox::TicktockWorker
    #   .after_work_callback = -> { MonitoredScheduledTask.ping(name: self.class.queue_name) }
    #
    setting :after_work_callback
  end

  def self.logger
    if defined? Rails
      Rails.logger
    else
      require 'logger' unless defined? Logger
      Logger.new(STDOUT)
    end
  end
end
