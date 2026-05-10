require 'rails_helper'

RSpec.describe ApplicationPolicy do
  let(:user) { build(:user) }
  let(:record) { double }

  describe "with valid user" do
    subject { described_class.new(user, record) }

    it 'denies index?' do
      expect(subject.index?).to be false
    end

    it 'denies show?' do
      expect(subject.show?).to be false
    end

    it 'denies create?' do
      expect(subject.create?).to be false
    end

    it 'denies update?' do
      expect(subject.update?).to be false
    end

    it 'denies destroy?' do
      expect(subject.destroy?).to be false
    end
  end

  describe "when user is nil" do
    it "raises error" do
      expect { described_class.new(nil, record) }.to raise_error(Pundit::NotAuthorizedError, "must be logged in")
    end
  end

  describe "Scope" do
    let(:user) { build(:user) }

    describe "#initialize" do
      it 'raises error when user is nil' do
        expect { described_class::Scope.new(nil, User) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "#resolve" do
      it 'raises NotImplementedError' do
        scope = described_class::Scope.new(user, User)
        expect { scope.resolve }.to raise_error(NotImplementedError)
      end
    end
  end
end
