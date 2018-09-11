# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

uri = ENV["REDISTOGO_URL"] || "redis://localhost:6379/"
$redis = Redis.new(:url => uri)

