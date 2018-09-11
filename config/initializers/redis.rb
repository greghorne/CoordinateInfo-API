# $redis = Redis::Namespace.new("coord_info", :redis => Redis.new)
#Redis.current = Redis.new(:host => '<VM IP>', :port => <VM PORT>, :password => '<PASSWORD>')
# $redis = Redis.new(host = '192.168.1.120', port = 6379, db = 15)
# $redis = Redis::Namespace.new(:host => '192.168.1.120', :port => 6379, db: "coord_info")
# require 'redis'
# $redis = Redis.new(host: "192.168.1.120", port: 6379, db: 15)

# $redis = Redis::Namespace.new("coord_info", :redis => Redis.new, :host => '192.168.1.120')

uri = URI.parse(ENV["REDISTOGO_URL"])
$redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)