class ApplicationPolicy
  NotAuthorizedError = Class.new(StandardError)

  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def authorize!
    raise NotAuthorizedError, "Nicht authentifiziert" unless user
    self
  end

  def admin? = user&.admin?
  def caretaker? = user&.caretaker?
  def parent? = user&.parent?
  def staff? = user&.staff?

  def index?   = staff?
  def show?    = staff?
  def create?  = staff?
  def new?     = staff?
  def update?  = staff?
  def edit?    = staff?
  def destroy? = admin?

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "#{self.class}#resolve not implemented"
    end

    private

    attr_reader :user, :scope
  end
end
