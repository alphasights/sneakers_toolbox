require 'sneakers_handlers'
require_relative './worker_timeout_error'
require_relative './sneakers_timer'

# This is a helper module that should be used to create workers that are
# executed periodically, using `ticktock` (https://github.com/alphasights/ticktock).
#
# Usage:
#
# class MyWorker
#   include TicktockWorker
#
#   configure queue: pistachio.my_queue_name,
#             frequency: 1.minute,
#             retry_on_failure: true # optional (default: false)

#   def process_message
#     # work
#   end
# end
#
# The values supported for the `frequency` configuration are the ones defined
# by `ticktock`. This value should be an `ActiveSupport::Duration`, like
# `5.seconds` or `24.hours`.
#
# These workers only need to return an `:ack` symbol if they are configured to
# `retry_on_failure`, otherwise the message will be discarded as soon as it is
# consumed.
#
module SneakersToolbox
  module TicktockWorker
    def self.included(base)
      base.include(Sneakers::Worker)
      base.extend(ClassMethods)
    end

    module ClassMethods

      # @param queue [String] The queue name
      #
      # @param frequency [ActiveSupport::Duration] A frequency supported by ticktock, like `1.minute`
      #
      # @param retry_on_failure [Boolean] Defines if the worker will use the
      #   `RetryHandler`, in which case it needs to return an `:ack symbol`
      def configure(queue:, frequency:, retry_on_failure: false, **other_properties)
        sufix = frequency.inspect.gsub(' ', '-')
        exchange_name = "ticktock.#{sufix}"

        queue_properties =  {
          durable: false,
          exchange: exchange_name,
          exchange_type: :fanout,
          workers: 1,
          threads: 1
        }.merge(other_properties)

        if retry_on_failure
          queue_properties = queue_properties.merge({
            ack: true,
            handler: SneakersHandlers::RetryHandler,
            max_retry: 5,
            arguments: { "x-dead-letter-exchange" => "#{exchange_name}.dlx",
                         "x-dead-letter-routing-key" => queue }
          })
        else
          queue_properties = queue_properties.merge({
            ack: false,
          })
        end

        from_queue(queue, queue_properties)
      end
    end

    def work(*args)
      SneakersTimer.timing(self.class) do
        LostDbConnectionHandler.with_connection do
          response = process_message

          SneakersToolbox.config.ticktock.after_work_callback&.call

          response
        end
      end
    rescue StandardError => e
      try_callbacks(e)
      raise e
    end

    private

    def try_callbacks(error)
      SneakersToolbox.config.ticktock.error_callbacks[error.class]&.call(error)
    end
  end
end
