require 'rails_helper'

RSpec.describe UserPolicy do
  let(:admin) { build(:user, :admin) }
  let(:author) { build(:user, :author) }
  let(:reader) { build(:user, :reader) }
  let(:other_user) { build(:user) }

  context 'index?' do
    it 'grants access to admin' do
      expect(described_class.new(admin, User).index?).to be true
    end
    it 'denies access to author' do
      expect(described_class.new(author, User).index?).to be false
    end
    it 'denies access to reader' do
      expect(described_class.new(reader, User).index?).to be false
    end
  end

  context 'show?' do
    it 'grants admin to view any user' do
      expect(described_class.new(admin, other_user).show?).to be true
    end
    it 'grants user to view themselves' do
      expect(described_class.new(reader, reader).show?).to be true
    end
    it 'denies reader to view other user' do
      expect(described_class.new(reader, other_user).show?).to be false
    end
  end

  context 'update?' do
    it 'grants admin to update any user' do
      expect(described_class.new(admin, other_user).update?).to be true
    end
    it 'grants user to update themselves' do
      expect(described_class.new(reader, reader).update?).to be true
    end
    it 'denies reader to update other user' do
      expect(described_class.new(reader, other_user).update?).to be false
    end
  end

  context 'destroy?' do
    it 'grants admin to destroy any user' do
      expect(described_class.new(admin, other_user).destroy?).to be true
    end
    it 'denies author to destroy user' do
      expect(described_class.new(author, other_user).destroy?).to be false
    end
    it 'denies reader to destroy user' do
      expect(described_class.new(reader, other_user).destroy?).to be false
    end
  end
end
