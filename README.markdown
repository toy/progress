# progress

http://github.com/toy/progress/tree/master

## DESCRIPTION:

Class to show progress during console script run

## SYNOPSIS:

    1000.times_with_progress('Wait') do |time| # title is optional
      puts time
    end

    [1, 2, 3].with_progress('Wait').each do |i|
      puts i
    end

    (1..100).with_progress('Wait').each do |i|
      puts i
    end

    {
      :a => 'a',
      :b => 'b',
      :c => 'c',
      :d => 'd',
    }.with_progress('Wait').each do |k, v|
      puts "#{k} => #{v}"
    end

    (1..10).with_progress('Outer').map do |a|
      (1..10).with_progress('Middle').map do |b|
        (1..10).with_progress('Inner').map do |c|
          [a, b, c]
        end
      end
    end

    symbols = []
    Progress.start('Input 100 symbols', 100) do
      while symbols.length < 100
        input = gets.scan(/\S/)
        symbols += input
        Progress.step input.length
      end
    end

or just

    symbols = []
    Progress('Input 100 symbols', 100) do
      while symbols.length < 100
        input = gets.scan(/\S/)
        symbols += input
        Progress.step input.length
      end
    end

Note - you will get WRONG progress if you use something like this:

    10.times_with_progress('A') do |time|
      10.times_with_progress('B') do
        # code
      end
      10.times_with_progress('C') do
        # code
      end
    end

But you can use this:

    10.times_with_progress('A') do |time|
      Progress.step 1, 2 do
        10.times_with_progress('B') do
          # code
        end
      end
      Progress.step 1, 2 do
        10.times_with_progress('C') do
          # code
        end
      end
    end

Or if you know that B runs 10 times faster than C:

    10.times_with_progress('A') do |time|
      Progress.step 1, 11 do
        10.times_with_progress('B') do
          # code
        end
      end
      Progress.step 10, 11 do
        10.times_with_progress('C') do
          # code
        end
      end
    end

## REQUIREMENTS:

ruby )))

## INSTALL:

    sudo gem install progress

## Copyright

Copyright (c) 2010-2011 Ivan Kuchin. See LICENSE.txt for details.
