require 'bundler/setup'
require './lib/books.rb'
require File.expand_path('../lib/books.rb', __FILE__)


mFile = File.expand_path('../../data/list.sqlite')

dataFile = Array.new
if ARGV.length > 0 then
  ARGV.each{|f|
    print "no such file(file=#{f})\n" unless File.exist?(f)
    dataFile.push(f)
  }
else
  dataFile = Dir.glob('./data/list.2017*').sort
  File.delete(mFile) if File.exist?(mFile)
end 

mList = MasterBookList.new(mFile)

dataFile.each{|f|
  print "marge file(#{f})\n"
  newList = BookList.new(f)
  mList.marge(newList)
  
  lastList = mList.getLastBookList

  # lastBookにs.outは含まれない
  sout = lastList.grep(sts: /s.out/)
  if sout.length > 0 then
    sout.dump
    raise "lastList Error!(include s.out)\n"
  end
  

  # lastBookは、最後に追加したリストに等しい
  diffList = lastList.diff(newList)
  diffList.keys.each{|k|
    print "-lastBooks"+"-"*50+"\n"
    lastList.dump
    print "-newBooks"+"-"*50+"\n"
    newList.dump
    print "-diffBooks"+"-"*50+"\n"
    diffList.dump
    print "-"*50,"\n"
    raise "lastList Error!(getLastBook Unmatch.file=#{f})"
      
  }
}

