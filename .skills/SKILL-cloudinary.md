# SKILL-cloudinary.md — Cloudinary Integration

> Read this when: working on image uploads, Media Library picker, transformation URLs, or asset housekeeping.

---

## Core Principle

**Rails never touches image bytes.** All uploads go directly from the browser to Cloudinary.
Rails only:
1. Generates an upload **signature** (proves the upload is authorized)
2. Receives and stores the `cloudinary_public_id` returned by Cloudinary
3. Generates **transformation URLs** on the fly from the stored `public_id`

---

## Configuration

```ruby
# config/initializers/cloudinary.rb
Cloudinary.config do |config|
  config.cloud_name = ENV['CLOUDINARY_CLOUD_NAME']
  config.api_key    = ENV['CLOUDINARY_API_KEY']
  config.api_secret = ENV['CLOUDINARY_API_SECRET']
  config.secure     = true  # always HTTPS
end
```

Required ENV vars: `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`

---

## Upload Architecture (Direct Signed Upload)

```
Browser                Rails Server              Cloudinary
  │                        │                         │
  │── GET /uploads/sig ───►│                         │
  │                        │ generate signature      │
  │◄── {sig, timestamp} ───│                         │
  │                        │                         │
  │── POST image ──────────────────────────────────►│
  │                        │                         │ process
  │◄── {public_id, url} ───────────────────────────│
  │                        │                         │
  │── POST public_id ─────►│                         │
  │                        │ save to DB              │
```

### Signature endpoint

```ruby
# app/controllers/uploads_controller.rb
# GET /uploads/signature?folder=thumb/2025-01&public_id=hello-world
def signature
  timestamp = Time.now.to_i
  params_to_sign = {
    timestamp:  timestamp,
    folder:     params.require(:folder),
    public_id:  params[:public_id]
  }.compact

  signature = Cloudinary::Utils.api_sign_request(params_to_sign, ENV['CLOUDINARY_API_SECRET'])

  render json: {
    signature:  signature,
    timestamp:  timestamp,
    api_key:    ENV['CLOUDINARY_API_KEY'],
    cloud_name: ENV['CLOUDINARY_CLOUD_NAME'],
    folder:     params[:folder],
    public_id:  params[:public_id]
  }
end
```

### Stimulus controller for direct upload

The `cloudinary-upload` Stimulus controller:
1. Catches the file input change event
2. Fetches a signature from `/uploads/signature`
3. POSTs the file to `https://api.cloudinary.com/v1_1/{cloud_name}/image/upload`
4. Puts the returned `public_id` into a hidden field for Rails form submission

---

## Folder Convention

| Asset type | Folder pattern | Example |
|---|---|---|
| Post thumbnail | `thumb/{YYYY-MM}/{post_id}` | `thumb/2025-01/42` |
| Slideshow images | `gallery/{YYYY-MM}/{post_id}/{position}` | `gallery/2025-01/42/01` |
| User avatars | `avatars/{user_id}` | `avatars/7` |

Always pass the `folder` parameter when generating a signature. This keeps Cloudinary organized and makes bulk deletion easy.

---

## Storing References in DB

**Always store `cloudinary_public_id`, never the full URL.**

```ruby
# Good
post.cloudinary_public_id = "thumb/2025-01/42"

# Bad — never store this
post.thumbnail_url = "https://res.cloudinary.com/yourcloud/image/upload/f_auto,q_auto/thumb/2025-01/42.jpg"
```

Why: transformation parameters change over time. If you store the URL, you have to update every row when parameters change. With `public_id` you generate the URL on the fly.

---

## Generating Transformation URLs

Always use `f_auto` (format) and `q_auto` (quality). These are mandatory for performance.

```ruby
# app/helpers/cloudinary_helper.rb

# Post thumbnail: 800×450 fill
Cloudinary::Utils.cloudinary_url(public_id,
  width: 800, height: 450, crop: :fill,
  fetch_format: :auto, quality: :auto)

# User avatar: square, face crop, circular
Cloudinary::Utils.cloudinary_url(public_id,
  width: size, height: size,
  crop: :fill, gravity: :face,
  fetch_format: :auto, quality: :auto,
  radius: :max)

# Slideshow: constrain width, preserve ratio
Cloudinary::Utils.cloudinary_url(public_id,
  width: 1200, crop: :limit,
  fetch_format: :auto, quality: :auto)
```

For model convenience:
```ruby
# app/models/post.rb
def thumbnail_url(**options)
  return nil unless cloudinary_public_id.present?
  Cloudinary::Utils.cloudinary_url(cloudinary_public_id,
    { fetch_format: :auto, quality: :auto }.merge(options))
end
```

---

## Media Library SDK (Pick Existing Assets)

Lets Admin users open a Cloudinary popup to select previously uploaded images without re-uploading.

Add to admin layout `<head>`:
```html
<script src="https://media-library.cloudinary.com/global/all.js"></script>
```

Stimulus controller (`cloudinary-media-library`) calls:
```javascript
const widget = cloudinary.createMediaLibrary(
  { cloud_name: '...', api_key: '...', multiple: false, max_files: 1 },
  { insertHandler: (data) => {
      const asset = data.assets[0]
      this.publicIdFieldTarget.value = asset.public_id
      this.previewTarget.src = asset.secure_url
  }}
)
widget.show()
```

ERB usage in admin forms:
```erb
<div data-controller="cloudinary-media-library"
     data-cloudinary-media-library-cloud-name-value="<%= ENV['CLOUDINARY_CLOUD_NAME'] %>"
     data-cloudinary-media-library-api-key-value="<%= ENV['CLOUDINARY_API_KEY'] %>">
  <%= f.hidden_field :cloudinary_public_id,
        data: { cloudinary_media_library_target: 'publicIdField' } %>
  <img data-cloudinary-media-library-target="preview" hidden />
  <button type="button" data-action="click->cloudinary-media-library#open">
    Pick from Media Library
  </button>
</div>
```

---

## Asset Renaming When Slug Changes

When a post's slug changes, images embedded in ActionText rich text fields will have stale URLs.

**Callback** in `Post`:
```ruby
after_update :rename_cloudinary_assets_job, if: :saved_change_to_slug?

def rename_cloudinary_assets_job
  RenameCloudinaryAssetsJob.perform_later(id)
end
```

**`RenameCloudinaryAssetsJob`** (queue: `media`):
1. Calls Cloudinary rename API for the thumbnail `public_id`
2. Iterates all `action_text_rich_texts` for this post
3. Uses `gsub` to replace old image URLs with new URLs
4. Saves updated rich text bodies

---

## Housekeeping: Orphan Deletion

`CloudinaryHousekeepingJob` (queue: `media`, scheduled: Sunday 3 AM):

1. Collects all `cloudinary_public_id` values from `posts`, `slideshow_assets`, and `users`
2. Queries Cloudinary API for all assets under `thumb/`, `gallery/`, `avatars/`
3. Deletes any asset whose `public_id` is not in the used set

```yaml
# config/sidekiq.yml
:schedule:
  cloudinary_housekeeping:
    cron: "0 3 * * 0"
    class: CloudinaryHousekeepingJob
```

---

## SlideshowAsset Model

```ruby
class SlideshowAsset < ApplicationRecord
  belongs_to :post
  validates :cloudinary_public_id, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  default_scope -> { order(:position) }

  def image_url(width: 1200)
    Cloudinary::Utils.cloudinary_url(cloudinary_public_id,
      width: width, crop: :limit, fetch_format: :auto, quality: :auto)
  end
end
```

---

## Testing: Stub Cloudinary

```ruby
# spec/support/cloudinary_helpers.rb
def stub_cloudinary_requests
  stub_request(:post, /cloudinary\.com.*upload/)
    .to_return(status: 200, body: {
      public_id: 'thumb/2025-01/test-post',
      secure_url: 'https://res.cloudinary.com/test/image/upload/test.jpg',
      width: 800, height: 450
    }.to_json, headers: { 'Content-Type' => 'application/json' })

  stub_request(:delete, /cloudinary\.com.*resources/)
    .to_return(status: 200, body: { deleted: {} }.to_json)

  stub_request(:post, /cloudinary\.com.*rename/)
    .to_return(status: 200, body: { public_id: 'new_id' }.to_json)
end
```

Include in `rails_helper.rb`:
```ruby
config.before(:each) { stub_cloudinary_requests }
```

---

## Common Pitfalls

- **Do not use `ActiveStorage` with Cloudinary** for this project — we use the `cloudinary` gem directly with direct signed uploads, not the ActiveStorage adapter.
- **`public_id` includes the folder path** — e.g., `thumb/2025-01/42`, not just `42`.
- **The signature must be server-generated** — never expose `api_secret` to the browser.
- **Cloudinary API rate limits** — the housekeeping job uses pagination (`max_results: 500`) to avoid hitting limits. Never call `Cloudinary::Api.resources` without `max_results`.
- **Avatar upload**: avatars use the same direct-upload pattern. The `public_id` is saved in `users.avatar_public_id`.
