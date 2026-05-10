require 'rails_helper'

RSpec.describe JwtDenylist, type: :model do
  describe 'database indexes' do
    it 'has index on jti column' do
      expect(ActiveRecord::Base.connection.indexes(:jwt_denylist).map(&:columns)).to include([ 'jti' ])
    end
  end

  describe 'Devise::JWT::RevocationStrategies::Denylist' do
    it 'includes the Denylist module' do
      expect(JwtDenylist.ancestors).to include(Devise::JWT::RevocationStrategies::Denylist)
    end
  end

  describe 'table name' do
    it 'uses jwt_denylist table' do
      expect(JwtDenylist.table_name).to eq('jwt_denylist')
    end
  end
end
