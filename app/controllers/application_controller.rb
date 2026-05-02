class ApplicationController < ActionController::Base
  include Authentication
  allow_browser versions: :modern
  stale_when_importmap_changes

  rescue_from ApplicationPolicy::NotAuthorizedError, with: :render_forbidden

  private

  def current_user
    Current.session&.user
  end
  helper_method :current_user

  def authorize!(record, policy_class: nil)
    klass = policy_class || "#{record.class}Policy".safe_constantize || ApplicationPolicy
    policy = klass.new(current_user, record)
    raise ApplicationPolicy::NotAuthorizedError unless policy.public_send("#{action_name}?")
    policy
  end

  def policy_scope(scope, policy_scope_class: nil)
    klass = policy_scope_class || "#{scope}Policy::Scope".safe_constantize
    return scope.all if klass.nil?
    klass.new(current_user, scope).resolve
  end

  def render_forbidden
    respond_to do |format|
      format.html { render plain: "Zugriff verweigert", status: :forbidden }
      format.json { render json: { error: "Forbidden" }, status: :forbidden }
    end
  end
end
