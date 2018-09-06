class Rack::Attack

    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new 

    throttle('req/ip', :limit => 100, :period => 60.seconds) do |req|
        Rails.logger.error("Rack::Attack Too many request attempts from IP: #{req.ip}; Limit 100 requests per minute.")
        req.ip 
    end

    # throttle('req/ip', :limit => 3, :period => 1.seconds) do |req|
    #     Rails.logger.error("Rack::Attack Too many requests per second from IP: #{req.ip}; Limit 3 requests per second.")
    #     req.ip 
    # end

end