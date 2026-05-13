module AdminHelper
  def role_badge_class(role)
    case role
    when "admin"
      "bg-purple-100 text-purple-800"
    when "author"
      "bg-blue-100 text-blue-800"
    when "reader"
      "bg-gray-100 text-gray-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end
end
