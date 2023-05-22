module Peplum
class Application
module Services

class Scheduler

  # Keep those out of RPC.
  class <<self
    def get_worker
      worker_info = agent.spawn
      return if !worker_info

      worker = Peplum::Application.connect( worker_info )
      self.workers[worker.url] = worker
      worker
    end

    def done_signal
      @done_signal ||= Queue.new
    end

    def wait
      self.done_signal.pop
    end

    def done
      self.done_signal << nil
    end

    def agent
      @agent ||= Processes::Agents.connect( Cuboid::Options.agent.url )
    end

    def workers
      @workers ||= {}
    end
  end

  def report( data, url )
    return if !(worker = self.class.workers.delete( url ))

    report_data << data

    worker.shutdown {}
    return unless self.class.workers.empty?

    Cuboid::Application.application.report report_data

    self.class.done
  end

  private

  def report_data
    @report_data ||= []
  end

end

end
end
end
