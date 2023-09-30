require "spec_helper"
require 'sneakers'
require_relative '../../lib/sneakers_toolbox'
require 'active_support/core_ext/numeric/time'
require 'json'
require 'sqlite3'
require 'active_record'

RSpec.describe SneakersToolbox::TicktockWorker do
  TicktockWorker = SneakersToolbox::TicktockWorker

  before { ActiveRecord::Base.establish_connection({adapter: 'sqlite3', database: ':memory:'}) }

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

  it "allows configuring global callback for after processing messages" do
    callback = double('callback', call: true)
    SneakersToolbox.config.ticktock.after_work_callback = callback
    expect(callback).to receive(:call)
    my_worker = Class.new do
      include SneakersToolbox::TicktockWorker
      def process_message
      end
    end

    my_worker.new.work
  end

  class MyError < StandardError
  end

  it "calls configured callbacks" do
    callback = -> {}
    SneakersToolbox.config.ticktock.error_callbacks = { MyError => callback }
    expect(callback).to receive(:call)
    my_worker = Class.new do
      include SneakersToolbox::TicktockWorker
      def process_message
        raise MyError
      end
    end

    expect { my_worker.new.work }.to raise_error(MyError)

  end
end
