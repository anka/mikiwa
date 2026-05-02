class KindergartenjahresUebergang
  def initialize(neues_jahr)
    @neues_jahr = neues_jahr
  end

  # Überträgt ausgewählte Kinder (IDs) inkl. Notfallkontakte und medizinische
  # Hinweise ins neue Kindergartenjahr. Implementierung vervollständigt in F3/F5.
  def durchfuehren(kind_ids)
    return if kind_ids.blank?
    Kind.where(id: kind_ids).find_each do |kind|
      kind.uebertragen_in(@neues_jahr)
    end
  rescue NameError
    # Kind-Modell noch nicht vorhanden (wird in F3 implementiert)
  end
end
