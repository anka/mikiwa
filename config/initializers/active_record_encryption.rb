# ActiveRecord::Encryption keys are managed via Rails Encrypted Credentials.
# Run: bin/rails db:encryption:init
# Then add the output to: bin/rails credentials:edit
#
# In development/test, a fixed key is used so encrypted fixtures work consistently.
if Rails.env.development? || Rails.env.test?
  ActiveRecord::Encryption.configure(
    primary_key:        Rails.application.credentials.dig(:active_record_encryption, :primary_key)        || "dev-primary-key-0000000000000000",
    deterministic_key:  Rails.application.credentials.dig(:active_record_encryption, :deterministic_key)  || "dev-deterministic-key-000000000000",
    key_derivation_salt: Rails.application.credentials.dig(:active_record_encryption, :key_derivation_salt) || "dev-key-derivation-salt-0000000000"
  )
end
