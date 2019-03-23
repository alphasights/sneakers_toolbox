require "sneakers_toolbox/version"
require 'sneakers_toolbox/lost_db_connection_handler'
require 'sneakers_toolbox/ticktock_worker'

module SneakersToolbox
  def self.logger
    if defined? Rails
      Rails.logger
    else
      require 'logger' unless defined? Logger
      Logger.new(STDOUT)
    end
  end
end
