module CloudinaryHelpers
  def stub_cloudinary_requests
    allow(Cloudinary::Utils).to receive(:cloudinary_url) do |public_id, **options|
      "https://res.cloudinary.com/test/image/upload/#{options[:transformations]}/#{public_id}"
    end
  end
end

RSpec.configure do |config|
  config.include CloudinaryHelpers
end
