class JwtDenylist
  include Mongoid::Document
  include Mongoid::Timestamps

  field :jti, type: String
  field :exp, type: Time

  index({ jti: 1 }, { unique: true })
  index({ exp: 1 }, { expire_after_seconds: 0 })

  def self.jwt_revoked?(payload, user)
    where(jti: payload['jti']).exists?
  end

  def self.revoke_jwt(payload, user)
    create!(jti: payload['jti'], exp: Time.at(payload['exp']))
  end
end
