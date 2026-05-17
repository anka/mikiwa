Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self
    policy.img_src     :self, :data, :blob
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self
    policy.connect_src :self
    policy.frame_src   "https://www.google.com"
    policy.worker_src  :self, :blob
    policy.manifest_src :self
  end

  # Per-request random nonce. Using request.session.id leaked the session
  # token into HTML and emitted an empty `nonce-` for anonymous requests,
  # which blocked all inline scripts/styles in production.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
