$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rspec'
require 'progress'

describe Progress do

  describe "integrity" do

    before do
      @io = double(:<< => nil, :tty? => false)
      Progress.stub(:io).and_return(@io)
      Progress.stub(:start_beeper)
      Progress.stub(:time_to_print?).and_return(true)
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

          class CallsToEach
            include Enumerable

            COUNT = 100
          end

          def init_calls_to_each
            @enum = CallsToEach.new
            @objects = 10.times.to_a
            @enum.should_receive(:each).once{ |&block|
              @objects.each(&block)
            }
          end

          it "should call each only one time for object with length" do
            init_calls_to_each
            @enum.should_receive(:length).and_return(10)
            got = []
            @enum.with_progress.each{ |o| got << o }.should == @enum
            got.should == @objects
          end

          it "should call each only one time for object without length" do
            init_calls_to_each
            got = []
            @enum.with_progress.each{ |o| got << o }.should == @enum
            got.should == @objects
          end

        end
      end
    end

    describe Integer do

      let(:count){ 666 }

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

end
