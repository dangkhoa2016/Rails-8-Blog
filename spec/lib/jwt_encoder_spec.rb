require 'rails_helper'

RSpec.describe JwtEncoder do
  let(:payload) { { user_id: 1, role: 'admin' } }

  describe ".encode" do
    it "returns a JWT token" do
      token = JwtEncoder.encode(payload)
      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3)
    end
  end

  describe ".decode" do
    let(:token) { JwtEncoder.encode(payload) }

    it "decodes the token" do
      decoded = JwtEncoder.decode(token)
      expect(decoded.first['user_id']).to eq(1)
      expect(decoded.first['role']).to eq('admin')
    end

    context "with invalid token" do
      it "raises JWT::DecodeError" do
        expect { JwtEncoder.decode('invalid.token.here') }.to raise_error(JWT::DecodeError)
      end
    end
  end
end
