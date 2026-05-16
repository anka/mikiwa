require "net/http"
require "uri"
require "json"
require "base64"

# F80: Erkennt Einträge auf einem (handgeschriebenen) Einkaufszettel via
# OpenAI Vision (gpt-5.4-mini) und liefert sie inklusive Kategorie zurück.
#
# Strukturell analog zu ShoppingItems::AutoClassifier (Net::HTTP,
# json_schema strict). Wird synchron aus dem Controller-Request heraus
# aufgerufen, weil der*die Betreuer*in aktiv auf das Ergebnis wartet.
module ShoppingItems
  class ImageRecognizer
    API_URL          = "https://api.openai.com/v1/chat/completions".freeze
    MODEL            = "gpt-5.4-mini".freeze
    TIMEOUT_SECONDS  = 30
    ALLOWED_CATEGORIES = ShoppingItem::CATEGORY_ORDER.freeze

    SYSTEM_PROMPT = <<~PROMPT.freeze
      Du extrahierst Artikel von einer handgeschriebenen Einkaufsliste aus
      einem österreichischen Kindergarten. Erkenne jeden Eintrag exakt
      einmal, normalisiere die Schreibweise leicht (Tippfehler, Großschreibung),
      und klassifiziere jeden Artikel in eine der vorgegebenen Kategorien.
      Bei Unsicherheit oder mehrdeutigen Einträgen wähle 'other'. Mengenangaben
      (z.B. "2 kg", "3 Packungen", "1 Liter") gehören in das Feld quantity –
      NICHT in das name-Feld. Wenn keine Mengenangabe erkennbar ist, setze
      quantity auf null. Falls eine Notiz erkennbar ist (z.B. "bio", "fettarm"),
      gib sie im Feld note an. Antworte ausschließlich im vorgegebenen JSON-Schema.
    PROMPT

    JSON_SCHEMA = {
      name:   "shopping_item_extraction",
      strict: true,
      schema: {
        type:                 "object",
        required:             [ "items" ],
        additionalProperties: false,
        properties: {
          items: {
            type: "array",
            items: {
              type:                 "object",
              required:             [ "name", "category", "quantity", "note" ],
              additionalProperties: false,
              properties: {
                name:     { type: "string" },
                category: { type: "string", enum: ALLOWED_CATEGORIES },
                quantity: { type: [ "string", "null" ] },
                note:     { type: [ "string", "null" ] }
              }
            }
          }
        }
      }
    }.freeze

    class << self
      def enabled?
        ENV["OPENAI_API_KEY"].to_s.strip.present?
      end

      def call(image_io, content_type: "image/jpeg")
        new(image_io, content_type: content_type).call
      end
    end

    def initialize(image_io, content_type: "image/jpeg")
      @image_io     = image_io
      @content_type = content_type
    end

    def call
      raise "OPENAI_API_KEY missing" unless self.class.enabled?

      response = fetch_completion(build_payload)
      content  = response.dig("choices", 0, "message", "content")
      parsed   = JSON.parse(content.to_s)
      raw      = parsed["items"]
      return [] unless raw.is_a?(Array)

      raw.filter_map { |entry| normalize_entry(entry) }
    rescue JSON::ParserError, NoMethodError, TypeError
      []
    end

    # Sichtbarer Hook für Tests – analog zu AutoClassifier.
    def fetch_completion(body)
      post_json(body)
    end

    private

    def normalize_entry(entry)
      return nil unless entry.is_a?(Hash)
      name = entry["name"].to_s.strip
      return nil if name.empty?

      category_str = entry["category"].to_s
      category     = ALLOWED_CATEGORIES.include?(category_str) ? category_str.to_sym : :other
      quantity     = entry["quantity"].is_a?(String) ? entry["quantity"].strip.presence : nil
      note         = entry["note"].is_a?(String) ? entry["note"].strip.presence : nil

      { name: name, category: category, quantity: quantity, note: note }
    end

    def build_payload
      {
        model:           MODEL,
        response_format: { type: "json_schema", json_schema: JSON_SCHEMA },
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user",   content: user_content }
        ]
      }
    end

    def user_content
      [
        { type: "text",      text: text_prompt },
        { type: "image_url", image_url: { url: data_url } }
      ]
    end

    def text_prompt
      lines = [ "Extrahiere alle Einträge dieser Einkaufsliste." ]
      lines << ""
      lines << "Verfügbare Kategorien (Wert → Beschreibung):"
      lines.concat(category_descriptions)
      lines.join("\n")
    end

    def category_descriptions
      ALLOWED_CATEGORIES.map do |key|
        "- #{key} → #{I18n.t("activerecord.attributes.shopping_item.categories.#{key}", default: key.humanize)}"
      end
    end

    def data_url
      bytes = @image_io.respond_to?(:read) ? @image_io.read : @image_io.to_s
      @image_io.rewind if @image_io.respond_to?(:rewind)
      "data:#{@content_type};base64,#{Base64.strict_encode64(bytes)}"
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
