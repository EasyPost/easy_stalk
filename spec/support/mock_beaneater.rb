module EasyStalk
  class MockBeaneater
    # TODO write some tests?
    class TubeCollection
      def self.[](name)
        @tubes ||= {}
        @tubes[name] ||= Tube.new
      end
    end
    class Tubes
      def watch!(tube_name)
        (@watched ||= []) << tube_name
      end
      def watched
        @watched
      end
      def reserve(timeout)
      end
    end
    class Tube
      def put(data, pri: 0, ttr: 30, delay: 0, tube_name: 'default')
        # no-op?
        @items ||= []
        @items << TubeItem.new(data, pri, ttr, Time.now + delay, tube_name)
      end
      def pop
        (@items ||= []).sort!
        if !@items.empty? && Time.now > @items.last.delay_until
          @items.delete_at(@items.size - 1).data
        end
      end
    end
    class TubeItemStats
      attr_accessor :releases
      def initialize(releases: 0)
        @releases = releases
      end
    end
    class TubeItem
      attr_accessor :data, :pri, :ttr, :delay_until
      def initialize(data, pri, ttr, delay_until, tube_name)
        @data, @pri, @ttr, @delay_until, @tube_name = data, pri, ttr, delay_until, tube_name
      end
      def body
        @data
      end
      def tube
        @tube_name
      end
      def <=>(other)
        if @delay_until < Time.now && other.delay_until < Time.now
          other.pri <=> @pri
        else
          other.delay_until <=> @delay_until
        end
      end
      def delete
      end
      def release(delay: 0)
      end
      def stats
        TubeItemStats.new(releases: 1)
      end
    end
    def tubes
      MockBeaneater::TubeCollection
    end
  end
end
