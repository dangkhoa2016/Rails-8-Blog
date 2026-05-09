class JwtEncoder
  require "jwt"

  def self.encode(payload)
    JWT.encode(payload, ENV.fetch("DEVISE_JWT_SECRET_KEY", "fallback_secret"), "HS256")
  end

  def self.decode(token)
    JWT.decode(token, ENV.fetch("DEVISE_JWT_SECRET_KEY", "fallback_secret"), true, algorithm: "HS256")
  end
end
