class TagBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :slug
  field :posts_count
end
