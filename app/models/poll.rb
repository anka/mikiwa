class Poll < ApplicationRecord
  include UuidPrimaryKey

  POLL_TYPES = %w[single multiple].freeze
  STATUSES   = %w[open closed].freeze

  ClosedError = Class.new(StandardError)

  belongs_to :group
  belongs_to :kindergarten_year
  belongs_to :created_by, class_name: "User"
  belongs_to :event, class_name: "Event", optional: true, foreign_key: :event_id

  has_many :poll_options, -> { order(:position, :created_at) }, dependent: :destroy
  has_many :votes, through: :poll_options

  accepts_nested_attributes_for :poll_options,
                                allow_destroy: true,
                                reject_if: :all_blank

  validates :title,             presence: true
  validates :poll_type,         inclusion: { in: POLL_TYPES }
  validates :status,            inclusion: { in: STATUSES }
  validates :group,             presence: true
  validates :kindergarten_year, presence: true
  validates :created_by,        presence: true
  validate  :at_least_one_option

  scope :ordered, -> { order(created_at: :desc) }

  def open?
    return false unless status == "open"
    deadline.nil? || deadline.future?
  end

  def close!
    update!(status: "closed")
  end

  def vote!(user:, option_ids:)
    raise ClosedError, "Poll is closed" unless open?

    case poll_type
    when "single"
      option_ids = Array(option_ids).first(1)
      votes.where(user: user).destroy_all
      option = poll_options.find(option_ids.first)
      Vote.create!(poll_option: option, user: user)
    when "multiple"
      votes.where(user: user).destroy_all
      Array(option_ids).each do |oid|
        option = poll_options.find(oid)
        Vote.create!(poll_option: option, user: user)
      end
    end
  end

  def votes_by_option
    poll_options.each_with_object({}) do |opt, hash|
      hash[opt] = opt.votes.includes(:user).map(&:user)
    end
  end

  private

  def at_least_one_option
    active = poll_options.reject(&:marked_for_destruction?)
    errors.add(:poll_options, "mindestens eine Option muss vorhanden sein") if active.empty?
  end
end
