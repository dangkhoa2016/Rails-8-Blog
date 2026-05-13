class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :email, :full_name, :role

  field :avatar_url do |user|
    user.avatar_url(size: 200) if user.avatar_public_id.present?
  end

  view :compact do
    fields :id, :full_name
    field :avatar_url do |user|
      user.avatar_url(size: 100) if user.avatar_public_id.present?
    end
  end
end
