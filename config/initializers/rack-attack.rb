class Rack::Attack

    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new 

    throttle('req/ip', :limit => 100, :period => 120.seconds) do |req|
        # Rails.logger.error("Rack::Attack Too many request attempts from IP: #{req.ip}; Limit 100 requests per minute.")
        req.ip 
    end

    self.throttled_response = ->(env) {
        retry_after = (env['rack.attack.match_data'] || {})[:period]
        [
          429,
          {'Content-Type' => 'application/json', 'Retry-After' => retry_after.to_s},
          [{error: "Too many request attempts.  Limit 100 requests per 2 minutes."}.to_json]
        ]
      }

end