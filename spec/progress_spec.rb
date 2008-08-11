require File.dirname(__FILE__) + '/spec_helper'
require 'progress'
require 'stringio'

describe Progress do
  before(:each) do
    class Progress
      def self.io=(io)
        @io = io
      end
    end
  end
  
  it "should show valid output" do
    Progress.io = io = StringIO.new
    Progress.start('Test', 1000) do
      io.string.should =~ /\.\.\./
      1000.times do |i|
        Progress.step
        io.string.should =~ Regexp.new("#{(i + 1) / 10.0}")
      end
    end
    io.string.should =~ Regexp.new("100.0")
  end

  it "should show valid output for each_with_progress" do
    Progress.io = io = StringIO.new
    a = Array.new(1000){ |i| i }
    c = 0
    a.each_with_progress('Test') do |i|
      io.string.should =~ (i == 0 ? /\.\.\./ : Regexp.new("#{i / 10.0}"))
      i.should == a[c]
      c += 1
    end
    io.string.should =~ Regexp.new("100.0")
  end

  it "should show valid output for times_with_progress" do
    Progress.io = io = StringIO.new
    c = 0
    1000.times_with_progress('Test') do |i|
      io.string.should =~ (i == 0 ? /\.\.\./ : Regexp.new("#{i / 10.0}"))
      i.should == c
      c += 1
    end
    io.string.should =~ Regexp.new("100.0")
  end
end
