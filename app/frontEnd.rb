require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader'
require File.expand_path('../lib/books.rb', __FILE__)

set :bind, '0.0.0.0'
set :port, 50080
set :environment, :production

set :dbFile, File.expand_path('../../data/list.sqlite', __FILE__)

def book_to_tr(mList,book)
  url = "/book/#{book.id}"
  css = "none"
  if book.sts == "s.out" then
    css = "s-out"
  elsif book.priceOff > 50.0 then
    css = "over50p"
  end
  lowestPrice = mList.getLowestPrice(book.id)
  lowestMark = (lowestPrice == book.price) ? "●" : ""
  

  return sprintf("<tr class='%s'><td><a href='%s'>%s</a>" +
                 "</td><td>%s</td><td>%s</td><td>%s</td>" + 
                 "<td>%5d</td><td>%5d</td><td>%3.1f%%</td>" + 
                 "<td>%s</td><td>%s</td></tr>",
                   css,url,book.title,
                   book.timestamp,book.maker,book.release,
                   book.listPrice,book.price,book.priceOff,
                   lowestMark,book.sts)
end

get '/' do
end

get '/list' do
  @listType="全リスト"
  mList = MasterBookList.new(settings.dbFile)
  bookList = mList.getLastBookList(false)
  @lastTimeStamp = mList.getLastTimeStamp
  @content = ''
  bookList.keys.sort.each{|t|
    book = bookList[t]
    @content = @content + book_to_tr(mList,book) + "\n"
  }

  erb :index
  
end

get '/listLastUpdate' do
  @listType="最終更新分リスト"
  mList = MasterBookList.new(settings.dbFile)
  bookList = mList.getLastBookList(false)
  @lastTimeStamp = mList.getLastTimeStamp
  @content = ''
  bookList.keys.sort.each{|t|
    book = bookList[t]
    next unless book.timestamp == @lastTimeStamp
    @content = @content + book_to_tr(mList,book) + "\n"
  }

  erb :index
end

get '/listLast1Day' do
  @listType="24時間以内更新分リスト"
  mList = MasterBookList.new(settings.dbFile)
  bookList = mList.getLastBookList(false)
  @lastTimeStamp = mList.getLastTimeStamp
  timeStampBefore1Day = (Time.now - (60*60*24)).strftime("%Y/%m/%d %H:%M")
  @content = ''
  bookList.keys.sort.each{|t|
    book = bookList[t]
    next if book.timestamp < timeStampBefore1Day
    @content = @content + book_to_tr(mList,book) + "\n"
  }

  erb :index
  
end

get '/book/:id' do
  id = params['id']
  raise "book id error.(#{id})" if /\A-?\d+\Z/
  mList = MasterBookList.new(settings.dbFile)
  prices = mList.getBookPrices(params['id'])
  @bookInfo = ''
  @bookInfo  = prices.book.to_htmlTr
  @priceInfo = ''
  prices.prices.each{|p|
    @priceInfo = @priceInfo +
      sprintf("<tr><td>%s</td><td>%d</td><td>%3.1f</td><td>%s</td></tr>",
              p[1],p[2],p[3],p[4])
  }

  erb :detail
end

