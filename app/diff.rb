require 'bundler/setup'
require File.expand_path('../lib/books.rb', __FILE__)

oldList = BookList.new(ARGV[0])
newList = BookList.new(ARGV[1])

diffList = oldList.diff(newList)

diffList.keys.sort.each{|t|
  diffBook = diffList[t]
  
  unless(diffBook.sts == "new") or (diffBook.sts == "s.out")then
    oldBook = oldList[t]
    printf("(%-5s) [ %s ]\n", diffBook.sts,diffBook.title)
    printf("  %s(%s) %4d \n",diffBook.maker, diffBook.release,diffBook.listPrice)
    printf("  %4d (%5.1f%% off) -> %4d (%5.1f%% off)\n", oldBook.price, oldBook.priceOff, diffBook.price, diffBook.priceOff)
    print "\n"
  else
    oldBook = oldList[t]
    printf("(%-5s) [ %s ]\n", diffBook.sts,diffBook.title)
    printf("  %s(%s) %4d \n",diffBook.maker, diffBook.release,diffBook.listPrice)
    printf("  %4d (%5.1f%% off)\n", diffBook.price, diffBook.priceOff)
    print "\n"
  end
}
