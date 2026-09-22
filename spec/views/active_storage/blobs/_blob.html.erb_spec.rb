require "rails_helper"

RSpec.describe "active_storage/blobs/_blob.html.erb", type: :view do
  let(:blob) { double(representable?: true, filename: double(extension: "png"), caption: nil, byte_size: 1, representation: "https://fallback.test/image.png") }

  it "renders responsive signed derived media attributes when the helper supplies a public mapping" do
    allow(view).to receive(:d7_image_attributes).and_return(src: "https://signed.test/800", srcset: "https://signed.test/320 320w", sizes: "fixed")

    render partial: "active_storage/blobs/blob", locals: { blob:, post: instance_double(Post) }

    expect(rendered).to include('src="https://signed.test/800"', 'srcset="https://signed.test/320 320w"', 'sizes="fixed"')
  end
end
