class Rack::Attack
  # Throttle login attempts per IP: max 5 failures in 10 minutes
  throttle("login/ip", limit: 5, period: 10.minutes) do |req|
    if req.path == "/session" && req.post?
      req.ip
    end
  end

  # Throttle magic link requests per IP
  throttle("magic_link/ip", limit: 5, period: 10.minutes) do |req|
    if req.path == "/magic_links" && req.post?
      req.ip
    end
  end

  # Throttle password reset per IP
  throttle("password_reset/ip", limit: 5, period: 10.minutes) do |req|
    if req.path == "/passwords" && req.post?
      req.ip
    end
  end

  self.throttled_responder = lambda do |_req|
    [ 429, { "Content-Type" => "text/plain" }, [ "Zu viele Anfragen. Bitte versuchen Sie es später erneut." ] ]
  end
end
