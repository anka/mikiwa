module ShoppingItems
  # F79: Async-Klassifikation eines ShoppingItems via OpenAI. Aufruf erfolgt
  # über das after_commit on: :create im Modell. No-op, wenn der Item-Eintrag
  # bereits manuell auf eine konkrete Kategorie gesetzt wurde – damit wird
  # die User-Auswahl niemals von der API überschrieben.
  class ClassifyJob < ApplicationJob
    queue_as :default

    retry_on StandardError, attempts: 3, wait: :polynomially_longer

    def perform(item_id)
      item = ShoppingItem.find_by(id: item_id)
      return unless item&.category_auto?
      return unless AutoClassifier.enabled?

      result = AutoClassifier.call(item)
      return if result.blank?

      item.reload
      return unless item.category_auto?

      item.update!(category: result)
    end
  end
end
