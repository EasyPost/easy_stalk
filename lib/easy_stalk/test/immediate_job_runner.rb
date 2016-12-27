module EasyStalk
  module Extensions
    module ImmediateJobRunner
      @active = false

      def self.active
        @active
      end

      def self.activate!
        @active = true
      end

      def self.deactivate!
        @active = false
      end
    end
  end
end
