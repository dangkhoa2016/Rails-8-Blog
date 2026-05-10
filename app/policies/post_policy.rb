class PostPolicy < ApplicationPolicy
  def index?   = true
  def show?    = true

  def create?  = user.author? || user.admin?

  def update?
    user.admin? || record.user == user
  end

  def destroy?
    user.admin? || record.user == user
  end

  def publish?
    user.admin? || record.user == user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.author?
        scope.where(user: user).or(scope.published)
      else
        scope.published
      end
    end
  end
end
