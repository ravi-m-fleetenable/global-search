class Rack::Attack
  # Throttle all requests by IP
  throttle('req/ip', limit: 300, period: 1.minute) do |req|
    req.ip unless req.path.start_with?('/health')
  end

  # Throttle search requests
  throttle('search/ip', limit: ENV.fetch('RATE_LIMIT_REQUESTS_PER_MINUTE', 100).to_i, period: 1.minute) do |req|
    if req.path.include?('/api/v1/search')
      req.ip
    end
  end

  # Throttle autocomplete requests (more lenient)
  throttle('autocomplete/ip', limit: 200, period: 1.minute) do |req|
    if req.path.include?('/autocomplete')
      req.ip
    end
  end

  # Throttle login attempts
  throttle('login/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/api/v1/users/sign_in' && req.post?
      req.ip
    end
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |env|
    retry_after = env['rack.attack.match_data'][:period]
    [
      429,
      {'Content-Type' => 'application/json', 'Retry-After' => retry_after.to_s},
      [{error: 'Rate limit exceeded. Please try again later.'}.to_json]
    ]
  end
end

# Enable Rack::Attack
Rails.application.config.middleware.use Rack::Attack
