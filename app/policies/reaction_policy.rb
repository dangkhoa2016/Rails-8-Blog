class ReactionPolicy < ApplicationPolicy
  def create?  = true
  def destroy? = user&.admin? || record.user == user
end
