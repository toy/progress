$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rspec'
require 'progress'

describe Progress do

  before do
    Progress.stay_on_line = true
    Progress.highlight = true
    Progress.set_terminal_title = true

    Progress.stub(:start_beeper)
    Progress.stub(:time_to_print?).and_return(true)
    Progress.stub(:eta)
    Progress.stub(:elapsed).and_return('0s')
  end

  describe "integrity" do

    before do
      @io = double(:<< => nil, :tty? => true)
      Progress.stub(:io).and_return(@io)
    end

    it "should return result from start block" do
      Progress.start('Test') do
        'test'
      end.should == 'test'
    end

    it "should return result from step block" do
      Progress.start 1 do
        Progress.step{ 'test' }.should == 'test'
      end
    end

    it "should return result from set block" do
      Progress.start 1 do
        Progress.set(1){ 'test' }.should == 'test'
      end
    end

    it "should return result from nested block" do
      [1, 2, 3].with_progress.map do |a|
        [1, 2, 3].with_progress.map do |b|
          a * b
        end
      end.should == [[1, 2, 3], [2, 4, 6], [3, 6, 9]]
    end

    it "should not raise errors on extra step or stop" do
      proc{
        3.times_with_progress do
          Progress.start 'simple' do
            Progress.step
            Progress.step
            Progress.step
          end
          Progress.step
          Progress.stop
        end
        Progress.step
        Progress.stop
      }.should_not raise_error
    end

    describe Enumerable do

      before :each do
        @a = 0...1000
      end

      describe "with_progress" do

        it "should not break each" do
          reference = @a.each
          @a.with_progress.each do |n|
            n.should == reference.next
          end
          proc{ reference.next }.should raise_error(StopIteration)
        end

        it "should not break find" do
          default = proc{ 'default' }
          @a.with_progress.find{ |n| n == 100 }.should == @a.find{ |n| n == 100 }
          @a.with_progress.find{ |n| n == 10000 }.should == @a.find{ |n| n == 10000 }
          @a.with_progress.find(default){ |n| n == 10000 }.should == @a.find(default){ |n| n == 10000 }
        end

        it "should not break map" do
          @a.with_progress.map{ |n| n * n }.should == @a.map{ |n| n * n }
        end

        it "should not break grep" do
          @a.with_progress.grep(100).should == @a.grep(100)
        end

        it "should not break each_cons" do
          reference = @a.each_cons(3)
          @a.with_progress.each_cons(3) do |values|
            values.should == reference.next
          end
          proc{ reference.next }.should raise_error(StopIteration)
        end

        describe "with_progress.with_progress" do

          it "should not change existing instance" do
            wp = @a.with_progress('hello')
            proc{ wp.with_progress('world') }.should_not change(wp, :title)
          end

          it "should create new instance with different title when called on WithProgress" do
            wp = @a.with_progress('hello')
            wp_wp = wp.with_progress('world')
            wp.title.should == 'hello'
            wp_wp.title.should == 'world'
            wp_wp.should_not == wp
            wp_wp.enumerable.should == wp.enumerable
          end

        end

        describe "calls to each" do

          def without_warnings
            verbosity = $VERBOSE
            $VERBOSE = nil
            result = yield
            $VERBOSE = verbosity
            result
          end

          it "should call each only once for Array" do
            enum = [1, 2, 3]
            enum.should_receive(:each).once.and_return(enum)
            enum.with_progress.each{ }.should == enum
          end

          it "should call each only once for Hash" do
            enum = {1 => 1, 2 => 2, 3 => 3}
            enum.should_receive(:each).once.and_return(enum)
            enum.with_progress.each{ }.should == enum
          end

          it "should call each only once for Set" do
            enum = [1, 2, 3].to_set
            enum.should_receive(:each).once.and_return(enum)
            enum.with_progress.each{ }.should == enum
          end

          if ''.is_a?(Enumerable) # ruby1.8
            it "should call each only once for String" do
              enum = "a\nb\nc"
              enum.should_receive(:each).once.and_return(enum)
              without_warnings do
                enum.with_progress.each{ }.should == enum
              end
            end
          end

          it "should call each only once for File (IO)" do
            enum = File.open(__FILE__)
            enum.should_receive(:each).once.and_return(enum)
            without_warnings do
              enum.with_progress.each{ }.should == enum
            end
          end

          it "should call each only once for StringIO" do
            enum = StringIO.new("a\nb\nc")
            enum.should_receive(:each).once.and_return(enum)
            without_warnings do
              enum.with_progress.each{ }.should == enum
            end
          end

        end
      end
    end

    describe Integer do

      let(:count){ 108 }

      it "should not break times_with_progress" do
        reference = count.times
        count.times_with_progress do |i|
          i.should == reference.next
        end
        proc{ reference.next }.should raise_error(StopIteration)
      end

      it "should not break times.with_progress" do
        reference = count.times
        count.times.with_progress do |i|
          i.should == reference.next
        end
        proc{ reference.next }.should raise_error(StopIteration)
      end

    end

  end

  describe "output" do

    class ChunkIo
      attr_reader :chunks
      def initialize
        @chunks = []
      end

      def <<(data)
        @chunks << data.to_s
      end
    end

    def stub_progress_io(klass)
      io = klass.new
      io.stub(:tty?).and_return(true)
      Progress.stub(:io).and_return(io)
      io
    end

    describe "validity" do

      def run_example_progress
        Progress.start 5, 'Test' do
          Progress.step 2, 'simle'

          Progress.step 2, 'times' do
            3.times.with_progress {}
          end

          Progress.step 'enum' do
            3.times.to_a.with_progress {}
          end
        end
      end

      def title(s)
        "\e]0;#{s}\a"
      end

      def hl(s)
        "\e[1m#{s}\e[0m"
      end

      def on_line(s)
        "\r" + s + "\e[K"
      end

      def line(s)
        s + "\n"
      end

      it "should produce valid output when staying on line" do
        Progress.stay_on_line = true

        @io = stub_progress_io(ChunkIo)
        run_example_progress

        @io.chunks.should == [
          on_line("Test: #{hl '......'}"),                      title('Test: ......'),
          on_line("Test: #{hl ' 40.0%'} - simle"),              title('Test:  40.0% - simle'),
          on_line("Test: #{hl ' 40.0%'} > #{hl '......'}"),     title('Test:  40.0% > ......'),
          on_line("Test: #{hl ' 53.3%'} > #{hl ' 33.3%'}"),     title('Test:  53.3% >  33.3%'),
          on_line("Test: #{hl ' 66.7%'} > #{hl ' 66.7%'}"),     title('Test:  66.7% >  66.7%'),
          on_line("Test: #{hl ' 80.0%'} > 100.0%"),             title('Test:  80.0% > 100.0%'),
          on_line("Test: #{hl ' 80.0%'} - times"),              title('Test:  80.0% - times'),
          on_line("Test: #{hl ' 80.0%'} > #{hl '......'}"),     title('Test:  80.0% > ......'),
          on_line("Test: #{hl ' 86.7%'} > #{hl ' 33.3%'}"),     title('Test:  86.7% >  33.3%'),
          on_line("Test: #{hl ' 93.3%'} > #{hl ' 66.7%'}"),     title('Test:  93.3% >  66.7%'),
          on_line("Test: 100.0% > 100.0%"),                     title('Test: 100.0% > 100.0%'),
          on_line("Test: 100.0% - enum"),                       title('Test: 100.0% - enum'),
          on_line("Test: 100.0% (elapsed: 0s) - enum") + "\n",  title(''),
        ]
      end

      it "should produce valid output when not staying on line" do
        Progress.stay_on_line = false

        @io = stub_progress_io(ChunkIo)
        run_example_progress

        @io.chunks.should == [
          line("Test: #{hl '......'}"),                  title('Test: ......'),
          line("Test: #{hl ' 40.0%'} - simle"),          title('Test:  40.0% - simle'),
          line("Test: #{hl ' 40.0%'} > #{hl '......'}"), title('Test:  40.0% > ......'),
          line("Test: #{hl ' 53.3%'} > #{hl ' 33.3%'}"), title('Test:  53.3% >  33.3%'),
          line("Test: #{hl ' 66.7%'} > #{hl ' 66.7%'}"), title('Test:  66.7% >  66.7%'),
          line("Test: #{hl ' 80.0%'} > 100.0%"),         title('Test:  80.0% > 100.0%'),
          line("Test: #{hl ' 80.0%'} - times"),          title('Test:  80.0% - times'),
          line("Test: #{hl ' 80.0%'} > #{hl '......'}"), title('Test:  80.0% > ......'),
          line("Test: #{hl ' 86.7%'} > #{hl ' 33.3%'}"), title('Test:  86.7% >  33.3%'),
          line("Test: #{hl ' 93.3%'} > #{hl ' 66.7%'}"), title('Test:  93.3% >  66.7%'),
          line("Test: 100.0% > 100.0%"),                 title('Test: 100.0% > 100.0%'),
          line("Test: 100.0% - enum"),                   title('Test: 100.0% - enum'),
          line("Test: 100.0% (elapsed: 0s) - enum"),     title(''),
        ]
      end

    end

    describe "different call styles" do

      let(:count_a){ 13 }
      let(:count_b){ 17 }

      before do
        reference_io = stub_progress_io(StringIO)
        count_a.times.with_progress('Test') do
          count_b.times.with_progress {}
        end
        @reference_output = reference_io.string

        @io = stub_progress_io(StringIO)
      end

      it "should output same when called without block" do
        Progress(count_a, 'Test')
        count_a.times do
          Progress.step do
            Progress.start(count_b)
            count_b.times do
              Progress.step
            end
            Progress.stop
          end
        end
        Progress.stop
        @io.string.should == @reference_output
      end

      it "should output same when called with block" do
        Progress(count_a, 'Test') do
          count_a.times do
            Progress.step do
              Progress.start(count_b) do
                count_b.times do
                  Progress.step
                end
              end
            end
          end
        end
        @io.string.should == @reference_output
      end

      it "should output same when called using with_progress on list" do
        count_a.times.to_a.with_progress('Test') do
          count_b.times.to_a.with_progress {}
        end
        @io.string.should == @reference_output
      end

    end

  end

end
