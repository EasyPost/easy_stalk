module EasyStalk
  class Configuration
    attr_accessor :logger
    attr_accessor :worker_on_fail

    def initialize
      @logger = Logger.new($stdout).tap do |log|
        log.progname = Module.nesting.last.name
      end
      @worker_on_fail = Proc.new { |job_class, job_body, ex|
        EasyStalk.logger.error "Worker for #{job_class} on tube[#{job_class.tube_name}] failed #{ex.message}"
        EasyStalk.logger.error ex.backtrace.join("\n")
      }
    end

  end
end
