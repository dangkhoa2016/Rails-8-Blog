class UserPolicy < ApplicationPolicy
  def index?   = user.admin?
  def show?    = user.admin? || record == user
  def update?  = user.admin? || record == user
  def destroy? = user.admin?
end
