class Kind < ApplicationRecord
  self.table_name = "kinder"

  include ImageAttachable

  belongs_to :gruppe
  belongs_to :kindergartenjahr
  has_many :eltern_kinder, class_name: "ElternKind", foreign_key: "kind_id", dependent: :destroy
  has_many :eltern, through: :eltern_kinder, source: :user
  has_one_attached :profilfoto

  validates_image_attachment :profilfoto

  FOTO_EINWILLIGUNG_OPTIONS = [ true, false ].freeze

  validates :vorname, presence: true
  validates :nachname, presence: true
  validates :geburtsdatum, presence: true
  validates :gruppe, presence: true
  validates :kindergartenjahr, presence: true
  validates :foto_einwilligung, inclusion: { in: FOTO_EINWILLIGUNG_OPTIONS, message: "muss angegeben werden" }

  scope :active, -> { where(aktiv: true) }
  scope :inactive, -> { where(aktiv: false) }

  def anzeigename
    rufname.presence || vorname
  end

  def vollstaendiger_name
    "#{vorname} #{nachname}"
  end

  def deaktivieren!
    update!(aktiv: false)
  end

  def uebertragen_in(neues_jahr)
    return if Kind.where(nachname: nachname, vorname: vorname, geburtsdatum: geburtsdatum,
                         kindergartenjahr_id: neues_jahr.id).exists?

    neues_kind = dup
    neues_kind.kindergartenjahr = neues_jahr
    neues_kind.aktiv = true
    neues_kind.save!

    eltern_kinder.find_each do |ek|
      ElternKind.create!(user_id: ek.user_id, kind_id: neues_kind.id, bemerkung: ek.bemerkung)
    end

    neues_kind
  end
end
