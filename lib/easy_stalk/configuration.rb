module EasyStalk
  class Configuration
    attr_accessor :logger

    def initialize
      @logger = Logger.new($stdout).tap do |log|
        log.progname = Module.nesting.last.name
      end
    end
  end
end
