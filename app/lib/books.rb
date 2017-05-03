require 'sqlite3'

class BookInfo
  attr_accessor :title, :timestamp, :sts, :maker, :release, :listPrice, :price, :priceOff
  # 拡張属性。DBから取得時のみセットされる
  attr_accessor :id
  def initialize()
    @title     = ""
    @timestamp = ""
    @maker     = ""
    @release   = ""
    @listPrice = 0
    @price     = 0
    @priceOff  = 0.0
    @sts = ""
    # 拡張属性。DBから取得時のみセットされる
    @id  = 0
  end
  
  def setArray(a)
    @title     = a[0] if a.length > 0
    @timestamp = a[1] if a.length > 1
    @maker     = a[2] if a.length > 2
    @release   = a[3] if a.length > 3
    @listPrice = a[4] if a.length > 4
    @price     = a[5] if a.length > 4
    @priceOff  = a[6] if a.length > 6
    @sts       = a[7] if a.length > 7
  end

  def setHash(h)
    @title      = h["title"]    if h.has_key?("title")
    @timestamp  = h["timestamp"] if h.has_key?("timestamp")
    @maker      = h["maker"] if h.has_key?("maker")
    @release    = h["release"] if h.has_key?("release")
    @listPrice  = h["listPrice"] if h.has_key?("listPrice")
    @price      = h["price"] if h.has_key?("price")
    @priceOff   = h["priceOff"] if h.has_key?("priceOff")
    @sts        = h["sts"] if h.has_key?("sts")
    @id         = h["id"]  if h.has_key?("id")
  end


  def setText(l)
    l.chomp!
    if(/^\[(.+)\]\((.+)\)(.+)\((.+)\)\s*(\d+)\s*->\s*(\d+)\s*\(([0-9.\-]+)%off\)\((.*)\)\s*$/ =~ l)then
      @title     = $1
      @timestamp = $2
      @maker     = $3
      @release   = $4
      @listPrice = $5.to_i
      @price     = $6.to_i
      @priceOff  = $7.to_f
      @sts       = $8
    else
      raise "format Error(#{l})"
    end
      
  end

  def to_s
    return sprintf("[%s](%s)%s(%s)%5d->%5d(%3.1f%%off)(%s)",
                     @title,@timestamp,@maker,@release,@listPrice,@price,@priceOff,@sts)
  end

  def to_json
    url = "/book/#{self.id}"
    json = "{"
    json = json + '"titile":'    + '"' + @titile    + '"' + ','
    json = json + '"timestamp":' + '"' + @timestamp + '"' + ','
    json = json + '"maker":'     + '"' + @maker     + '"' + ','
    json = json + '"release":'   + '"' + @release   + '"' + ','
    json = json + '"listPrice":'       + @listPrice       + ','
    json = json + '"price":'           + @price           + ','
    json = json + '"priceOff":'        + @priceOff        + ','
    json = json + '"sts":'       + '"' + @sts       + '"' + ','
    json = json + '"id":'              + @id              + ','
    json = json + '"detail":'          + url              + ','
    json = json + "}"

    return json
  end


  def to_htmlTr
    url = "/book/#{self.id}"
    css = "none"
    if self.sts == "s.out" then
      css = "s-out"
    elsif self.priceOff > 50.0 then
      css = "over50p"
    end

    return sprintf("<tr class='%s'><td><a href='%s'>%s</a></td><td>%s</td><td>%s</td><td>%s</td><td>%5d</td><td>%5d</td><td>%3.1f%%</td><td>%s</td></tr>",
                     css,url,@title,@timestamp,@maker,@release,@listPrice,@price,@priceOff,@sts)
  end

  def dump
      return sprintf("[%s]\n    (%s)%s(%s)%5d->%5d(%3.1f%%off)(%s)",
                     @title,@timestamp,@maker,@release,@listPrice,@price,@priceOff,@sts)

  end


end

class BookPrices
  attr_accessor :book, :prices
  def initialize(book,history)
    @book = book
    @prices = history
  end
end

class BookList < Hash
  def initialize(file=nil)
    unless(file == nil)then
      self.load(file)
    end
  end

  def load(file)
    File.open(file,encoding: 'utf-8'){|f|
      f.each_line{|l|
        book = BookInfo.new
        book.setText(l)
        self.add(book)
      }
    }
  end
 
  def add(book)
    raise "Duplicate Book Title(#{book.title})" if(self.has_key?(book.title))
    self[book.title] = book
  end

  def getTimeStamp
    return self[self.keys[0]].timestamp
  end

  def diff(otherList)
    diffs = BookList.new
    titles = (self.keys + otherList.keys).uniq
    titles.sort.each{|t|
      unless(self.has_key?(t))then
        book = otherList[t]
        book.sts = "new"
        diffs.add(book)
        next
      end
      unless(otherList.has_key?(t))then
        book  = self[t]
        book.sts = "s.out"
        book.timestamp = otherList.getTimeStamp
        diffs.add(book)
        next
      end
      if(self[t].price < otherList[t].price)then
        book = otherList[t]
        book.sts = "up"
        diffs.add(book)
        next
      end
      if(self[t].price > otherList[t].price)then
        book = otherList[t]
        book.sts = "down"
        diffs.add(book)
        next
      end
    }
    return diffs
  end

  def ==(otherList)
    diffs = self.diff(otherList)
    if diffs.keys.length == 0 then
      return true
    else
      return false
    end 
  end

  def grep(title: /.*/, sts: /.*/)
    grepList = BookList.new
    self.keys.each{|t|
      if t =~ title and self[t].sts =~ sts then
        grepList[t] = self[t]
      end
    }
    return grepList

  end

  def to_json
    json = "[\n"

    self.keys.each_with_i{|t,i|
      book = self[t]
      json = json + "," if i > 0
      json = json + book.to_json + "\n"
    }

    json = json + "\n]"

  end

  def save(file)
    File.open(file,"w",encoding: 'utf-8'){|f|
      self.keys.sort.each{|t|
        f.print(self[t].to_s,"\n")
      }
    }
  end

  def dump
    self.keys.each{|k|
      print self[k].dump,"\n"
    }
  end
end

class MasterBookList
  def initialize(db)
    @titleList = 'titleList'
    @priceList = 'priceList'
    self.load(db)
  end

  def createTitleList
    sql = "create table  #{@titleList} (" +
        " title     text," +
        " timestamp text," +
        " maker     text," +
        " release   text," +
        " listPrice integer," +
        " grp       text," +
        " siries    text," +
        " primary key(title, maker)" +
      ")"
    @db.execute(sql)
  end

  def createPriceList
    sql = "create table  #{@priceList} (" +
        " id        integer ," +
        " timestamp text    ," +
        " price     integer," +
        " priceOff  float," +
        " sts       text," +
        " primary key (id,timestamp)" +
      ")"
    @db.execute(sql)
  end

  def load(db)
    @db = SQLite3::Database.new(db)
    self.createTitleList if(@db.table_info(@titleList).length == 0)
    self.createPriceList if(@db.table_info(@priceList).length == 0)
  end

  def getBookId(book)
    sql = "select rowid from #{@titleList} where title='#{book.title}' and maker='#{book.maker}'"
    rows = @db.execute(sql)
    if rows[0] == nil then
      return nil
    else
      return rows[0][0]
    end
  end

  def hasBook?(book)
    id = self.getBookId(book)
    if id == nil then
      return false
    else
      return true
    end
  end

  def insertPrice(book)
    id = self.getBookId(book)
    sql  = "insert into #{@priceList} values(" +
      "#{id},'#{book.timestamp}',#{book.price},#{book.priceOff},'#{book.sts}')"
    @db.execute(sql)
  end

  def updatePrice(book)
    id = self.getBookId(book)
    sql  = "update  #{@priceList} set " +
      " price=#{book.price}," +
      " priceOff=#{book.priceOff}," +
      " sts='#{book.sts}'" +
      " where id=#{id} and timestamp='#{book.timestamp}'"
    @db.execute(sql)
  end

  def insertTitle(book)
    sql  = "insert into #{@titleList} (title,maker,timestamp,release,listPrice,grp,siries) " +
      "values('#{book.title}','#{book.maker}','#{book.timestamp}'," +
      "'#{book.release}',#{book.listPrice},'','')"
    @db.execute(sql)
  end

  def addBookList(bookList)
    bookList.keys.each{|t|
      book = bookList[t]
      case book.sts
      when "up"
        self.insertPrice(book)
      when "down"
        self.insertPrice(book)
      when "new"
        self.insertTitle(book) unless hasBook?(book)
        self.insertPrice(book)
      when "s.out"
        self.insertPrice(book)
      end
    }
  end

  def getBook(id)
    sql  = "select * from #{@titleList} where rowid=#{id}"
    title = @db.execute(sql)
    sql  = "select * from #{@priceList} where id=#{id} order by timestamp desc"
    price = @db.execute(sql)

    info = Hash.new
    info["title"]     = title[0][0]
    info["timestamp"] = price[0][1]
    info["maker"]     = title[0][2]
    info["release"]   = title[0][3]
    info["listPrice"] = title[0][4]
    info["price"]     = price[0][2]
    info["priceOff"]  = price[0][3]
    if(info["priceOff"] == 0.0)and(info["listPrice"]>0)then
      info["priceOff"] = 100.0 - (info["price"]*100.0/info["listPrice"])
    end
    info["sts"]       = price[0][4]
    info["id"]        = id


    book = BookInfo.new
    book.setHash(info)
    return book
  end

  def getLastBookList(soutOff = true)
    bookList = BookList.new
    sql  = "select rowid from #{@titleList}"
    bookIds = @db.execute(sql)
    bookIds.each{|id|
      book = self.getBook(id[0])
      bookList.add(book)
    }
    if(soutOff) then
      return bookList.grep(sts: /^(?!s\.out)/)
    else
      return bookList
    end
  end

  def getBookPrices(id)
    book = self.getBook(id)
    sql  = "select * from #{@priceList} where id=#{id} order by timestamp"
    prices = @db.execute(sql)

    bookPrices = BookPrices.new(book,prices)
    return bookPrices
  end

  def getLowestPrice(id)
    sql  = "select min(price) from #{@priceList} where id=#{id} order by timestamp"
    lows = @db.execute(sql)

    return lows[0][0]
  end

  def getLastTimeStamp
    sql  = "select max(timestamp) from #{@priceList}"
    lastTimeStamps = @db.execute(sql)
    return lastTimeStamps[0][0]
  end

  def marge(bookList)
    lastList = self.getLastBookList
    diffList = lastList.diff(bookList)
    self.addBookList(diffList)
  end

  def save
    @db.close
  end


  def createList
    @book = BookInfo.new
    @db.execute(@book.to_creqteSql(@table))
  end
end
