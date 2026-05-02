class KindergartenjahresUebergang
  def initialize(neues_jahr)
    @neues_jahr = neues_jahr
  end

  def durchfuehren(kind_ids)
    return if kind_ids.blank?
    Kind.where(id: kind_ids).find_each do |kind|
      kind.uebertragen_in(@neues_jahr)
    end
  end
end
