class CommentPolicy < ApplicationPolicy
  def index?   = true
  def show?    = true
  def create?  = true
  def destroy? = user&.admin? || record.user == user
end
