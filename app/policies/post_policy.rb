class PostPolicy < ApplicationPolicy
  def index?   = true
  def show?    = true

  def create?  = user&.author? || user&.admin?

  def update?
    user&.admin? || record.user == user
  end

  def destroy?
    user&.admin? || record.user == user
  end

  def publish?
    user&.admin? || record.user == user
  end

  def schedule?
    user.admin?
  end

class Scope < ApplicationPolicy::Scope
     def resolve
       if user.nil?
         scope.where(status: "published")
       elsif user.admin?
         scope.all
       elsif user.author?
         scope.where(user: user).or(scope.where(status: "published"))
       else
         scope.where(status: "published")
       end
     end
end
end
