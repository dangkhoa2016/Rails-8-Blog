require 'rails_helper'

RSpec.describe PostPolicy do
  let(:admin) { build(:user, :admin) }
  let(:author) { build(:user, :author) }
  let(:reader) { build(:user, :reader) }
  let(:author_user) { build(:user, :author) }
  let(:post) { double('Post', user: author_user, id: 1) }

  context 'index?' do
    it 'grants access to admin' do
      expect(described_class.new(admin, post).index?).to be true
    end
    it 'grants access to author' do
      expect(described_class.new(author, post).index?).to be true
    end
    it 'grants access to reader' do
      expect(described_class.new(reader, post).index?).to be true
    end
  end

  context 'show?' do
    it 'grants access to admin' do
      expect(described_class.new(admin, post).show?).to be true
    end
    it 'grants access to author' do
      expect(described_class.new(author, post).show?).to be true
    end
    it 'grants access to reader' do
      expect(described_class.new(reader, post).show?).to be true
    end
  end

  context 'create?' do
    it 'grants access to admin' do
      expect(described_class.new(admin, post).create?).to be true
    end
    it 'grants access to author' do
      expect(described_class.new(author, post).create?).to be true
    end
    it 'denies access to reader' do
      expect(described_class.new(reader, post).create?).to be false
    end
  end

  context 'update?' do
    it 'grants access to admin' do
      expect(described_class.new(admin, post).update?).to be true
    end
    it 'grants access to post owner' do
      expect(described_class.new(author_user, post).update?).to be true
    end
    it 'denies access to reader' do
      expect(described_class.new(reader, post).update?).to be false
    end
  end

  context 'destroy?' do
    it 'grants access to admin' do
      expect(described_class.new(admin, post).destroy?).to be true
    end
    it 'grants access to post owner' do
      expect(described_class.new(author_user, post).destroy?).to be true
    end
    it 'denies access to reader' do
      expect(described_class.new(reader, post).destroy?).to be false
    end
  end

  context 'publish?' do
    it 'grants access to admin' do
      expect(described_class.new(admin, post).publish?).to be true
    end
    it 'grants access to post owner' do
      expect(described_class.new(author_user, post).publish?).to be true
    end
    it 'denies access to reader' do
      expect(described_class.new(reader, post).publish?).to be false
    end
  end
end
