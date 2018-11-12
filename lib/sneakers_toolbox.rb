require "sneakers_toolbox/version"
require 'sneakers_toolbox/lost_db_connection_handler'

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
