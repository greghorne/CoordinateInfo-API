class Rack::Attack

    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new # defaults to Rails.cache
    
end