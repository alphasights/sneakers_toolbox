module SneakersToolbox
  # Clears dead connections from ActiveRecord connection pool
  #
  # It sometimes happens when using Amazon RDS over QuotaGuard tunnel, that a
  # DB connection is lost but Rails still keeps it in the connection pool
  #
  # This results in StatementInvalid errors and service outage - because
  # eventually the pool can get filled with these dead connections that Rails
  # thinks are still alive.
  #
  # This method solves it by rescuing the "ActiveRecord::StatementInvalid" and
  # clearing active connections, thus forcing rails to re-establish them.
  class LostDbConnectionHandler
    def self.with_connection
      ActiveRecord::Base.connection_pool.with_connection { yield }
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.error("Cleaning active connections after exception: #{e}")
      ActiveRecord::Base.clear_active_connections!

      raise e
    end
  end
end
