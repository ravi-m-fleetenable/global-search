class ApplicationController < ActionController::API
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from Mongoid::Errors::DocumentNotFound, with: :not_found
  rescue_from Pundit::NotAuthorizedError, with: :unauthorized
  rescue_from ActionController::ParameterMissing, with: :bad_request

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :phone, :role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :phone])
  end

  private

  def not_found(exception)
    render json: {
      success: false,
      error: 'Resource not found',
      message: exception.message
    }, status: :not_found
  end

  def unauthorized(exception)
    render json: {
      success: false,
      error: 'Unauthorized access',
      message: exception.message || 'You are not authorized to perform this action'
    }, status: :forbidden
  end

  def bad_request(exception)
    render json: {
      success: false,
      error: 'Bad request',
      message: exception.message
    }, status: :bad_request
  end

  def render_error(message, status: :unprocessable_entity)
    render json: {
      success: false,
      error: message
    }, status: status
  end

  def render_success(data, message: nil, status: :ok)
    response = { success: true }
    response[:message] = message if message
    response.merge!(data)

    render json: response, status: status
  end
end
