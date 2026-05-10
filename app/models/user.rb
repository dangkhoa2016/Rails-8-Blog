class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :confirmable,
         :lockable,
         :timeoutable,
         :trackable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist

  ROLES = %w[admin author reader].freeze

  validates :role, inclusion: { in: ROLES }
  validates :full_name, presence: true, length: { maximum: 100 }

  scope :admins,  -> { where(role: "admin") }
  scope :authors, -> { where(role: "author") }
  scope :readers, -> { where(role: "reader") }

  def admin?;  role == "admin";  end
  def author?; role == "author"; end
  def reader?; role == "reader"; end

  def jwt_payload
    super.merge("role" => role)
  end

  def avatar_url(size: 200)
    return nil unless avatar_public_id.present?
    Cloudinary::Utils.cloudinary_url(avatar_public_id,
      width: size, height: size, crop: :fill, gravity: :face, fetch_format: :auto)
  end
end
