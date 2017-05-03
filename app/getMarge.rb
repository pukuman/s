require 'bundler/setup'

system("ruby getList.rb")
dataFile = File.expand_path("../../data", __FILE__) + "/list." + Time.now.strftime("%Y%m%d")
system("ruby marge.rb #{dataFile}")
