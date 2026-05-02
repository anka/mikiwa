class Mitteilung < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :sent_by, class_name: "User"

  has_many :mitteilung_groups, dependent: :destroy
  has_many :groups, through: :mitteilung_groups
  has_many :posteingaenge, class_name: "Posteingang", dependent: :destroy

  has_one_attached :attachment

  validates :title,    presence: true
  validates :body,     presence: true
  validates :sent_by,  presence: true
  validate  :at_least_one_group

  scope :ordered, -> { order(created_at: :desc) }

  def deliver!
    recipient_users.each do |user|
      next if posteingaenge.exists?(user: user)
      entry = posteingaenge.create!(user: user)
      MitteilungMailer.notification(self, user).deliver_later
    end
  end

  def recipient_users
    parent_ids = groups.flat_map do |group|
      group.children.active.includes(:parent_children).flat_map { |child|
        child.parent_children.map(&:user_id)
      }
    end.uniq
    User.where(id: parent_ids)
  end

  private

  def at_least_one_group
    active = mitteilung_groups.reject(&:marked_for_destruction?)
    errors.add(:mitteilung_groups, "mindestens eine Gruppe muss zugeordnet sein") if active.empty?
  end
end
