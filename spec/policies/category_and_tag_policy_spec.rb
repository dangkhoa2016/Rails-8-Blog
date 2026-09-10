# frozen_string_literal: true

require "rails_helper"

RSpec.describe "admin-only taxonomy policies" do
  let(:admin) { build(:user, :admin) }
  let(:reader) { build(:user, :reader) }

  [ CategoryPolicy, TagPolicy ].each do |policy_class|
    it "allows only an admin to manage #{policy_class.name.delete_suffix('Policy').downcase.pluralize}" do
      record = instance_double(policy_class.name.delete_suffix("Policy"))

      [ :create?, :update?, :destroy? ].each do |action|
        expect(policy_class.new(admin, record).public_send(action)).to be(true)
        expect(policy_class.new(reader, record).public_send(action)).to be(false)
        expect(policy_class.new(nil, record).public_send(action)).to be_nil
      end
    end
  end
end
