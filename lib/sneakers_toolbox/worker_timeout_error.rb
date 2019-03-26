module SneakersToolbox
  class WorkerTimeoutError < StandardError
    def initialize(klass)
      @klass = klass
    end

    def to_s
      message
    end

    def message
      timeout = @klass.queue_opts[:timeout_job_after] || Sneakers::CONFIG[:timeout_job_after]
      "Worker '#{@klass.name}' timed out after #{timeout} seconds."
    end
  end
end
