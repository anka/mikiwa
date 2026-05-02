class Abstimmung < ApplicationRecord
  include UuidPrimaryKey

  POLL_TYPES = %w[einfach mehrfach].freeze
  STATUSES   = %w[offen geschlossen].freeze

  ClosedError = Class.new(StandardError)

  belongs_to :group
  belongs_to :kindergarten_year
  belongs_to :created_by, class_name: "User"
  belongs_to :event, class_name: "Event", optional: true, foreign_key: :event_id

  has_many :abstimmung_optionen, -> { order(:position, :created_at) },
           class_name: "AbstimmungOption", dependent: :destroy
  has_many :stimmen, through: :abstimmung_optionen

  accepts_nested_attributes_for :abstimmung_optionen,
                                allow_destroy: true,
                                reject_if: :all_blank

  validates :title,              presence: true
  validates :poll_type,          inclusion: { in: POLL_TYPES }
  validates :status,             inclusion: { in: STATUSES }
  validates :group,              presence: true
  validates :kindergarten_year,  presence: true
  validates :created_by,         presence: true
  validate  :at_least_one_option

  scope :ordered, -> { order(created_at: :desc) }

  def open?
    return false unless status == "offen"
    deadline.nil? || deadline.future?
  end

  def close!
    update!(status: "geschlossen")
  end

  def vote!(user:, option_ids:)
    raise ClosedError, "Abstimmung ist geschlossen" unless open?

    case poll_type
    when "einfach"
      option_ids = Array(option_ids).first(1)
      stimmen.where(user: user).destroy_all
      option = abstimmung_optionen.find(option_ids.first)
      Stimme.create!(abstimmung_option: option, user: user)
    when "mehrfach"
      stimmen.where(user: user).destroy_all
      Array(option_ids).each do |oid|
        option = abstimmung_optionen.find(oid)
        Stimme.create!(abstimmung_option: option, user: user)
      end
    end
  end

  def votes_by_option
    abstimmung_optionen.each_with_object({}) do |opt, hash|
      hash[opt] = opt.stimmen.includes(:user).map(&:user)
    end
  end

  private

  def at_least_one_option
    active = abstimmung_optionen.reject(&:marked_for_destruction?)
    errors.add(:abstimmung_optionen, "mindestens eine Option muss vorhanden sein") if active.empty?
  end
end
