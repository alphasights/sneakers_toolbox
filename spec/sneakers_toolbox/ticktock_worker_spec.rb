require "spec_helper"
require 'sneakers'
require_relative '../../lib/sneakers_toolbox'
require 'active_support/core_ext/numeric/time'
require 'json'
require 'sqlite3'
require 'active_record'

RSpec.describe SneakersToolbox::TicktockWorker do
  TicktockWorker = SneakersToolbox::TicktockWorker

  it "configures queue with given parameters" do
    queue_opts = Class.new do
      include TicktockWorker
      configure queue: "queue-name", frequency: 1.minute
    end.queue_opts

    expect(queue_opts[:durable]).to eql(false)
    expect(queue_opts[:ack]).to eql(false)
    expect(queue_opts[:exchange]).to eql("ticktock.1-minute")
    expect(queue_opts[:exchange_type]).to eql(:fanout)
    expect(queue_opts[:handler]).to be_nil
  end

  it "configures queue with retry handler" do
    queue_opts = Class.new do
      include TicktockWorker
      configure queue: "queue-name", frequency: 5.seconds, retry_on_failure: true
    end.queue_opts

    expect(queue_opts[:durable]).to eql(false)
    expect(queue_opts[:ack]).to eql(true)
    expect(queue_opts[:exchange]).to eql("ticktock.5-seconds")
    expect(queue_opts[:exchange_type]).to eql(:fanout)
    expect(queue_opts[:handler]).to eql(SneakersHandlers::RetryHandler)
    expect(queue_opts[:max_retry]).to eql(5)
    expect(queue_opts[:arguments]).to eql({
      "x-dead-letter-exchange" => "ticktock.5-seconds.dlx",
      "x-dead-letter-routing-key" => "queue-name"
    })
  end

  it "raises custom timeout error" do
    ActiveRecord::Base.establish_connection({adapter: 'sqlite3', database: ':memory:'})
    worker = Class.new do
      include TicktockWorker

      configure queue: "queue-name",
                frequency: 1.minute,
                ack: true

      def process_message
        raise Timeout::Error
      end
    end.new

    mock_honeybadger = double('Honeybadger')
    stub_const('Honeybadger', mock_honeybadger)
    expect {
      expect(mock_honeybadger).to receive(:notify).with(SneakersToolbox::WorkerTimeoutError.new(worker.class))
      worker.work({}.to_json)
    }.to raise_error(Timeout::Error)
  end
end
