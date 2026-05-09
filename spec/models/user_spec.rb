require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:full_name) }
    it { should validate_length_of(:full_name).is_at_most(100) }
    it { should validate_inclusion_of(:role).in_array(%w[admin author reader]) }
  end

  describe 'devise modules' do
    it 'includes database_authenticatable' do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it 'includes registerable' do
      expect(User.devise_modules).to include(:registerable)
    end

    it 'includes recoverable' do
      expect(User.devise_modules).to include(:recoverable)
    end

    it 'includes rememberable' do
      expect(User.devise_modules).to include(:rememberable)
    end

    it 'includes validatable' do
      expect(User.devise_modules).to include(:validatable)
    end

    it 'includes confirmable' do
      expect(User.devise_modules).to include(:confirmable)
    end

    it 'includes lockable' do
      expect(User.devise_modules).to include(:lockable)
    end

    it 'includes timeoutable' do
      expect(User.devise_modules).to include(:timeoutable)
    end

    it 'includes trackable' do
      expect(User.devise_modules).to include(:trackable)
    end

    it 'includes jwt_authenticatable' do
      expect(User.devise_modules).to include(:jwt_authenticatable)
    end
  end

  describe 'scopes' do
    let!(:admin) { create(:user, :admin) }
    let!(:author) { create(:user, :author) }
    let!(:reader) { create(:user, :reader) }

    describe '.admins' do
      it 'returns only admin users' do
        expect(User.admins).to include(admin)
        expect(User.admins).not_to include(author, reader)
      end
    end

    describe '.authors' do
      it 'returns only author users' do
        expect(User.authors).to include(author)
        expect(User.authors).not_to include(admin, reader)
      end
    end

    describe '.readers' do
      it 'returns only reader users' do
        expect(User.readers).to include(reader)
        expect(User.readers).not_to include(admin, author)
      end
    end
  end

  describe 'role methods' do
    let(:admin) { create(:user, :admin) }
    let(:author) { create(:user, :author) }
    let(:reader) { create(:user, :reader) }

    describe '#admin?' do
      it 'returns true for admin user' do
        expect(admin.admin?).to be true
      end

      it 'returns false for author user' do
        expect(author.admin?).to be false
      end

      it 'returns false for reader user' do
        expect(reader.admin?).to be false
      end
    end

    describe '#author?' do
      it 'returns true for author user' do
        expect(author.author?).to be true
      end

      it 'returns false for admin user' do
        expect(admin.author?).to be false
      end

      it 'returns false for reader user' do
        expect(reader.author?).to be false
      end
    end

    describe '#reader?' do
      it 'returns true for reader user' do
        expect(reader.reader?).to be true
      end

      it 'returns false for admin user' do
        expect(admin.reader?).to be false
      end

      it 'returns false for author user' do
        expect(author.reader?).to be false
      end
    end
  end

  describe '#avatar_url' do
    let(:user) { create(:user, avatar_public_id: nil) }

    context 'when avatar_public_id is present' do
      let(:user_with_avatar) { create(:user, avatar_public_id: 'avatars/test123') }

      it 'returns a Cloudinary URL' do
        allow(Cloudinary::Utils).to receive(:cloudinary_url).and_return('https://res.cloudinary.com/test/image/upload/avatars/test123')
        expect(user_with_avatar.avatar_url).to include('avatars/test123')
      end
    end

    context 'when avatar_public_id is nil' do
      it 'returns nil' do
        expect(user.avatar_url).to be_nil
      end
    end
  end
end
