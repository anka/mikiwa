# F80: Foto-Import von Einkaufsliste-Einträgen
#
# Akzeptiert ein Bild via Multipart-Upload, ruft synchron den
# ShoppingItems::ImageRecognizer (OpenAI Vision) auf und persistiert die
# erkannten Items in einer ActiveRecord-Transaktion mit der vom Vision-Call
# gelieferten Kategorie. Items werden NICHT mit category='auto' angelegt,
# damit der after_commit-Hook keinen zusätzlichen ClassifyJob triggert.
module ShoppingLists
  class PhotoImportsController < ApplicationController
    before_action :require_staff!
    before_action :set_list, if: -> { params[:shopping_list_id].present? }

    def create
      unless ShoppingItems::ImageRecognizer.enabled?
        flash[:alert] = "Foto-Erkennung ist derzeit deaktiviert."
        return redirect_to_referer_or_lists(status: :unprocessable_entity)
      end

      if params[:image].blank?
        flash[:alert] = "Bitte ein Foto auswählen."
        return redirect_to_referer_or_lists(status: :unprocessable_entity)
      end

      recognized = recognize_items!(params[:image])
      target     = target_list

      if recognized.empty?
        redirect_to redirect_target_for(target),
                    alert: "Konnte keine Items erkennen. Bitte erneut versuchen."
      else
        persist_items!(target, recognized)
        redirect_to redirect_target_for(target),
                    notice: "#{recognized.size} #{recognized.size == 1 ? 'Item' : 'Items'} erkannt."
      end
    rescue RecognitionError
      target = target_list
      redirect_to redirect_target_for(target),
                  alert: "Erkennung fehlgeschlagen, bitte erneut versuchen."
    end

    private

    # F80: Wrapper-Fehler für alle Service-/HTTP-/Parse-Fehler aus dem
    # Vision-Aufruf — wird im Action via rescue gefangen.
    class RecognitionError < StandardError; end

    def set_list
      @list = ShoppingList.find(params[:shopping_list_id])
    end

    def target_list
      @target_list ||= @list || build_new_list!
    end

    def build_new_list!
      ShoppingList.create!(
        title:             "Einkaufsliste #{I18n.l(Date.current, format: :long)}",
        event_date:        Date.current,
        kindergarten_year: active_kindergarten_year,
        created_by:        current_user
      )
    end

    def recognize_items!(image)
      io           = image.respond_to?(:tempfile) ? image.tempfile : image
      content_type = image.respond_to?(:content_type) ? image.content_type : "image/jpeg"
      ShoppingItems::ImageRecognizer.call(io, content_type: content_type)
    rescue StandardError => e
      Rails.logger.warn("F80 ImageRecognizer failed: #{e.class}: #{e.message}")
      raise RecognitionError, e.message
    end

    def persist_items!(list, recognized)
      ShoppingItem.transaction do
        base_position = (list.shopping_items.maximum(:position) || -1) + 1
        recognized.each_with_index do |entry, index|
          list.shopping_items.create!(
            name:     entry[:name],
            note:     entry[:note],
            category: entry[:category].to_s,
            position: base_position + index
          )
        end
      end
    end

    def redirect_target_for(list)
      list.persisted? ? shopping_list_path(list) : shopping_lists_path
    end

    def redirect_to_referer_or_lists(status:)
      fallback = @list ? shopping_list_path(@list) : shopping_lists_path
      redirect_to(request.referer || fallback, status: status)
    end

    def require_staff!
      return if current_user&.staff?
      head :forbidden
    end
  end
end
