require "net/http"
require "uri"
require "json"

# F79: Klassifiziert einen ShoppingItem-Namen über die OpenAI Chat-Completions API
# mit Structured Outputs (json_schema strict). Liefert ein Symbol aus
# ShoppingItem::CATEGORY_ORDER oder :other.
#
# Aufruf normal über ShoppingItems::ClassifyJob, damit Timeouts/Rate-Limits
# über ActiveJob-Retries abgefangen werden.
module ShoppingItems
  class AutoClassifier
    API_URL          = "https://api.openai.com/v1/chat/completions".freeze
    MODEL            = "gpt-4o-mini".freeze
    TIMEOUT_SECONDS  = 10
    MAX_OUTPUT_TOKENS = 50
    ALLOWED_RESULTS  = (ShoppingItem::CATEGORY_ORDER).freeze

    SYSTEM_PROMPT = <<~PROMPT.freeze
      Du klassifizierst Artikel auf Einkaufslisten für einen österreichischen Kindergarten.
      Wähle EXAKT eine Kategorie aus der vorgegebenen Liste.
      Wenn du dir unsicher bist oder der Artikel mehrdeutig ist, wähle 'other'.
      Antworte ausschließlich im vorgegebenen JSON-Schema.
    PROMPT

    JSON_SCHEMA = {
      name:   "shopping_item_classification",
      strict: true,
      schema: {
        type:                 "object",
        required:             [ "category" ],
        additionalProperties: false,
        properties: {
          category: { type: "string", enum: ALLOWED_RESULTS }
        }
      }
    }.freeze

    class << self
      def enabled?
        ENV["OPENAI_API_KEY"].to_s.strip.present?
      end

      def call(item)
        new(item).call
      end
    end

    def initialize(item)
      @item = item
    end

    def call
      raise "OPENAI_API_KEY missing" unless self.class.enabled?

      response = fetch_completion(build_payload)
      content  = response.dig("choices", 0, "message", "content")
      parsed   = JSON.parse(content.to_s)
      value    = parsed["category"].to_s

      ALLOWED_RESULTS.include?(value) ? value.to_sym : :other
    rescue JSON::ParserError, NoMethodError, TypeError
      :other
    end

    # Sichtbarer Hook für Tests (stubbar via with_stub). Im Default ruft er
    # die OpenAI-API auf; Tests können das Verhalten austauschen, ohne den
    # tatsächlichen HTTP-Layer zu treffen.
    def fetch_completion(body)
      post_json(body)
    end

    private

    def build_payload
      {
        model:           MODEL,
        max_tokens:      MAX_OUTPUT_TOKENS,
        response_format: { type: "json_schema", json_schema: JSON_SCHEMA },
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user",   content: user_prompt }
        ]
      }
    end

    def user_prompt
      lines = [ "Artikel: #{@item.name}" ]
      lines << "Notiz: #{@item.note}" if @item.note.present?
      lines << ""
      lines << "Verfügbare Kategorien (Wert → Beschreibung):"
      lines.concat(category_descriptions)
      lines << ""
      lines << "Gib die passendste Kategorie zurück."
      lines.join("\n")
    end

    def category_descriptions
      ALLOWED_RESULTS.map do |key|
        "- #{key} → #{I18n.t("activerecord.attributes.shopping_item.categories.#{key}", default: key.humanize)}"
      end
    end

    def post_json(body)
      uri  = URI(API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = TIMEOUT_SECONDS
      http.open_timeout = TIMEOUT_SECONDS

      request = Net::HTTP::Post.new(uri.path,
                                     "Content-Type"  => "application/json",
                                     "Authorization" => "Bearer #{ENV['OPENAI_API_KEY']}")
      request.body = body.to_json

      response = http.request(request)
      unless response.is_a?(Net::HTTPSuccess)
        raise "OpenAI HTTP #{response.code}: #{response.body}"
      end

      JSON.parse(response.body)
    end
  end
end
