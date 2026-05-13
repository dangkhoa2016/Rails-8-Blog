require "rails_helper"

RSpec.describe Setting, type: :model do
  subject { Setting.new(key: "test_key", value: "test_value", value_type: "string") }

  describe "validations" do
    it { should validate_presence_of(:key) }
    it { should validate_uniqueness_of(:key) }
    it { should validate_inclusion_of(:value_type).in_array(%w[string integer boolean array json]) }
    it { should validate_inclusion_of(:category).in_array(%w[general security media email rate_limit]) }
  end

  describe ".get" do
    it "returns the typed value for existing setting" do
      Setting.create!(key: "test_int", value: "42", value_type: "integer")
      expect(Setting.get("test_int")).to eq(42)
    end

    it "returns default value for non-existing setting" do
      expect(Setting.get("non_existing", "default")).to eq("default")
    end

    it "caches the result in Redis" do
      Setting.create!(key: "cached_key", value: "cached_value", value_type: "string")
      
      expect(Rails.cache).to receive(:fetch).with("setting:cached_key", expires_in: 5.minutes).and_call_original
      Setting.get("cached_key")
    end
  end

  describe ".set" do
    it "creates a new setting" do
      expect {
        Setting.set("new_key", "new_value")
      }.to change(Setting, :count).by(1)
    end

    it "updates existing setting" do
      Setting.create!(key: "existing_key", value: "old_value", value_type: "string")
      Setting.set("existing_key", "new_value")
      
      expect(Setting.find_by(key: "existing_key").value).to eq("new_value")
    end

    it "invalidates cache after setting" do
      expect(Rails.cache).to receive(:delete).with("setting:test_key")
      Setting.set("test_key", "test_value")
    end

    it "infers type correctly for integer" do
      Setting.set("int_key", 123)
      expect(Setting.find_by(key: "int_key").value_type).to eq("integer")
    end

    it "infers type correctly for boolean" do
      Setting.set("bool_key", true)
      expect(Setting.find_by(key: "bool_key").value_type).to eq("boolean")
    end

    it "infers type correctly for array" do
      Setting.set("array_key", ["a", "b", "c"])
      expect(Setting.find_by(key: "array_key").value_type).to eq("array")
    end
  end

  describe "#typed_value" do
    it "returns integer for integer type" do
      setting = Setting.create!(key: "int", value: "42", value_type: "integer")
      expect(setting.typed_value).to eq(42)
    end

    it "returns boolean for boolean type" do
      setting = Setting.create!(key: "bool", value: "true", value_type: "boolean")
      expect(setting.typed_value).to eq(true)
    end

    it "returns array for array type" do
      setting = Setting.create!(key: "arr", value: '["a","b"]', value_type: "array")
      expect(setting.typed_value).to eq(["a", "b"])
    end

    it "returns hash for json type" do
      setting = Setting.create!(key: "json", value: '{"key":"value"}', value_type: "json")
      expect(setting.typed_value).to eq({ "key" => "value" })
    end

    it "returns string for string type" do
      setting = Setting.create!(key: "str", value: "hello", value_type: "string")
      expect(setting.typed_value).to eq("hello")
    end
  end
end
