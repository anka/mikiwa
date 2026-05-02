class ApplicationJob < ActiveJob::Base
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3
  retry_on Net::TimeoutError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError
end
