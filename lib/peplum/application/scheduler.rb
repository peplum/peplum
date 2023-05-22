module Peplum
class Application

class Scheduler

  def initialize(*)
    super

    @done_signal = Queue.new
  end

  def get_worker
    worker_info = agent.spawn
    return if !worker_info

    worker = Peplum::Application.connect( worker_info )
    self.workers[worker.url] = worker
    worker
  end

  def workers
    @workers ||= {}
  end

  def report( data, url )
    return if !(worker = workers.delete( url ))

    report_data << data

    worker.shutdown {}
    return unless workers.empty?

    Cuboid::Application.application.report report_data

    @done_signal << nil
  end

  def wait
    @done_signal.pop
  end

  def agent
    @agent ||= Processes::Agents.connect( Cuboid::Options.agent.url )
  end

  private

  def report_data
    @report_data ||= []
  end

end

end
end
