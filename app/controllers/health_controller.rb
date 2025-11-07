class HealthController < ActionController::API
  def show
    health_status = {
      status: 'ok',
      timestamp: Time.current.iso8601,
      version: '1.0.0',
      services: check_services
    }

    status_code = health_status[:services].values.all? { |s| s[:status] == 'ok' } ? :ok : :service_unavailable

    render json: health_status, status: status_code
  end

  private

  def check_services
    {
      mongodb: check_mongodb,
      redis: check_redis
    }
  end

  def check_mongodb
    start_time = Time.current
    Mongoid.default_client.command(ping: 1)
    response_time = ((Time.current - start_time) * 1000).round(2)

    {
      status: 'ok',
      response_time_ms: response_time
    }
  rescue StandardError => e
    {
      status: 'error',
      message: e.message
    }
  end

  def check_redis
    return { status: 'disabled' } unless Rails.cache.is_a?(ActiveSupport::Cache::RedisCacheStore)

    start_time = Time.current
    Rails.cache.write('health_check', '1', expires_in: 10.seconds)
    Rails.cache.read('health_check')
    response_time = ((Time.current - start_time) * 1000).round(2)

    {
      status: 'ok',
      response_time_ms: response_time
    }
  rescue StandardError => e
    {
      status: 'error',
      message: e.message
    }
  end
end
