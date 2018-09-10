$redis = Redis::Namespace.new("coord_info", :redis => Redis.new)
#Redis.current = Redis.new(:host => '<VM IP>', :port => <VM PORT>, :password => '<PASSWORD>')
