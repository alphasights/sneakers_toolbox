# Integrates seamlessly with https://github.com/librato/librato-logreporter when defined
class SneakersTimer
  def self.timing(worker_class)
    if defined?(Librato) && Librato.respond_to?(:timing)
      Librato.timing("sneakers_worker.timing.#{worker_class}") { yield }
    else
      yield
    end
  end
end
