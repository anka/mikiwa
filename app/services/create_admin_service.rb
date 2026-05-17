class CreateAdminService
  Result = Struct.new(:status, :user, :message, keyword_init: true) do
    def created?  = status == :created
    def existing? = status == :existing
    def skipped?  = status == :skipped
  end

  ENV_EMAIL    = "ADMIN_EMAIL".freeze
  ENV_PASSWORD = "ADMIN_PASSWORD".freeze

  def self.call(logger: $stdout)
    new(logger: logger).call
  end

  def initialize(logger: $stdout)
    @logger = logger
  end

  def call
    email    = ENV[ENV_EMAIL].to_s.strip
    password = ENV[ENV_PASSWORD].to_s

    if email.blank? || password.blank?
      return warn_and_skip(
        "#{ENV_EMAIL} oder #{ENV_PASSWORD} ist nicht gesetzt – Admin-Anlage wird übersprungen."
      )
    end

    existing = User.find_by(email: email)
    if existing
      return Result.new(
        status:  :existing,
        user:    existing,
        message: "Admin-Account #{email} existiert bereits – keine Änderung."
      ).tap { |r| log(r.message) }
    end

    user = User.new(
      email:    email,
      password: password,
      role:     "admin"
    )

    if user.save
      Result.new(
        status:  :created,
        user:    user,
        message: "Admin-Account #{email} wurde angelegt."
      ).tap { |r| log(r.message) }
    else
      warn_and_skip(
        "Admin-Account konnte nicht angelegt werden: #{user.errors.full_messages.join(', ')}"
      )
    end
  end

  private

  def warn_and_skip(message)
    Rails.logger.warn(message) if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
    log("⚠ #{message}")
    Result.new(status: :skipped, user: nil, message: message)
  end

  def log(message)
    @logger.puts(message) if @logger.respond_to?(:puts)
  end
end
