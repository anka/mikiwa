class AddVersicherungsdatenToKinder < ActiveRecord::Migration[8.1]
  def change
    add_column :kinder, :krankenkasse, :string
    add_column :kinder, :versicherungsnummer, :string
  end
end
