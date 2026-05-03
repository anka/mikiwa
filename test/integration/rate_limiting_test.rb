require "test_helper"

class RateLimitingTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "rate_limit_user@test.de",
      password: "sicherespasswort1234",
      role: "caretaker"
    )
    @original_cache = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!
  end

  teardown do
    Rack::Attack.reset!
    Rack::Attack.cache.store = @original_cache
    @user.destroy!
  end

  # TS-006-S01: 6. Login-Versuch von derselben IP wird mit 429 geblockt
  test "6. fehlgeschlagener Login-Versuch von einer IP wird mit 429 blockiert" do
    5.times do
      post session_path,
           params: { email: @user.email, password: "falschespasswort1234" },
           headers: { "REMOTE_ADDR" => "1.2.3.4" }
    end

    post session_path,
         params: { email: @user.email, password: "falschespasswort1234" },
         headers: { "REMOTE_ADDR" => "1.2.3.4" }

    assert_response 429
  end

  test "5 fehlgeschlagene Versuche sind noch erlaubt" do
    5.times do
      post session_path,
           params: { email: @user.email, password: "falschespasswort1234" },
           headers: { "REMOTE_ADDR" => "5.6.7.8" }
      assert_response :unprocessable_entity
    end
  end
end
