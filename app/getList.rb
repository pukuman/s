require 'bundler/setup'
require 'mechanize'
require File.expand_path('../lib/books.rb', __FILE__)


def getPrice(t)
  price = "0"
  if( /([0-9,]+)/ =~ t.to_s) then
    price = $1 
  end
  price.gsub!(/,/,'')
  return price.to_i
end

def getDate(t)
  date = "0000/00/00"
  date = $1 if( /([0-9\/]+)/ =~ t)
  return date
end

def getSurugayaId(t)
  id = ''
  if ( t =~ /([A-Z0-9]+)$/ ) then
    id = $1
  end
  return id
end


urls = {
  '小学館プロダクション' => 'http://www.suruga-ya.jp/search?category=70101&search_word=&restrict[]=brand=小学館プロダクション&restrict[]=sale%20classified=中古',
  '小学館集英社プロダクション' => 'http://www.suruga-ya.jp/search?category=70101&search_word=&restrict[]=brand=小学館集英社プロダクション&restrict[]=sale%20classified=中古',
  '小学館プロダク' => 'http://www.suruga-ya.jp/search?category=70101&search_word=&restrict[]=brand=小学館プロダク&restrict[]=sale%20classified=中古',
  '小学館' => 'http://www.suruga-ya.jp/search?category=70101&search_word=&restrict[]=brand=小学館&restrict[]=sale%20classified=中古',
  'ビレッジブックス' => 'http://www.suruga-ya.jp/search?category=70101&search_word=&restrict[]=brand=ヴィレッジブックス&restrict[]=sale%20classified=中古',
  'ビレッジブッックス' => 'http://www.suruga-ya.jp/search?category=70101&search_word=&restrict[]=brand=ヴィレッッジブックス&restrict[]=sale%20classified=中古',
  'ジャイブ' => 'http://www.suruga-ya.jp/search?category=70101&search_word=&restrict[]=brand=ジャイブ&restrict[]=sale%20classified=中古',
  'みすず書房' => 'http://www.suruga-ya.jp/search?category=70101&search_word=&restrict[]=brand=みすず書房&restrict[]=sale%20classified=中古',
  '飛鳥新社' => 'http://www.suruga-ya.jp/search?category=70101&search_word=&restrict[]=brand=飛鳥新社&restrict[]=sale%20classified=中古',
}
#url = 'http://www.suruga-ya.jp/search?category=70101&search_word=&restrict[]=hendou=値下げ'

agent = Mechanize.new

timestamp = Time.now.strftime("%Y/%m/%d %H:%M")
dataDir     = File.expand_path('../../data', __FILE__)
nowFile     = "#{dataDir}/list." + Time.now.strftime("%Y%m%d")
sortFile    = "#{dataDir}/list.sort"
oldFile     = "#{dataDir}/list.old"
diffFile    = "#{dataDir}/list.diff"
historyFile = "#{dataDir}/list.history"

FileUtils.mkdir_p(dataDir) unless Dir.exists?(dataDir)
system("touch #{historyFile}") unless File.exists?(historyFile)


books = BookList.new
urls.keys.each{|k|
  url = urls[k]
  page = agent.get(url)
  pageMax = 10
  pageCounts = 1
  while(true)
    page.search('.item').each{|item|
      s_id    = getSurugayaId(item.search('.thum').at("a").attributes["href"].text)
      title   = item.search('.title').inner_text
      maker   =  item.search('.brand').inner_text
      release = getDate(item.search('.release_date').inner_text)
#      price   = getPrice(item.search('.item_price').search('.price').inner_text)
#      listPrice = getPrice(item.search('.item_price').search('.price_teika').inner_text)
      price = 0
      price_timesale = 0
      listPrice = 0
      prices = item.search('.item_price').search('.price_teika')
      prices.each{|t|
        case t.inner_text
        when  /定価/
          listPrice = getPrice(t)
        when  /中古/
          price = getPrice(t)
        else
          # セール時はコメントなしなので、ここにくるはず
          price_timesale = getPrice(t)
        end
      }

      # セール時の値段付け替え
      if price == 0 and price_timesale > 0 then
        price = price_timesale
      end

      if price <= 0 then
        printf( "not add:price=zero? %s,%s\n",title,timestamp)
        next
      end

      priceOff = (listPrice > 0) ? (listPrice-price)*100.0/listPrice : 0.0
      book = BookInfo.new()


      book.setArray([title,timestamp,maker,release,listPrice,price,priceOff,s_id])
      books.add(book)
    }
    break if page.search('.next').css("a")[0] == nil
    nextPage =  page.search('.next').css("a")[0][:href]
    break if( (nextPage == nil) or (nextPage.length == 0) )
    page = page.link_with(:href => nextPage).click
    pageCounts += 1
    break if pageCounts > pageMax
    sleep(2)
  end
}

books.save(nowFile)

