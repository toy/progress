$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rspec'
require 'progress'

describe Progress do

  describe "integrity" do

    before do
      @io = double
      @io.stub(:<<)
      @io.stub(:tty?).and_return(false)
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

  end

end
