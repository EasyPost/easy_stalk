require_relative '../job'
require_relative 'immediate_job_runner'

module EasyStalk
  module Extensions
    module RunImmediate
      def enqueue(beanstalk_connection, priority: nil, time_to_run: nil, delay: nil, delay_until: nil, tube_name: nil)
        if EasyStalk::Extensions::ImmediateJobRunner.active
          self.call
        else
          super
        end
      end
    end
  end
end

module EasyStalk
  class Job
    prepend EasyStalk::Extensions::RunImmediate
  end
end
