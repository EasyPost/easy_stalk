module EasyStalk
  module DescendantTracking
    def self.included(base)
      base.extend(ClassMethods)
    end
    module ClassMethods
      # Automatically keeps track of objects which subclass the included module
      def inherited(subclass)
        (@descendants ||= []) << subclass
      end
      def descendants
        @descendants ||= []
      end
    end
  end
end
