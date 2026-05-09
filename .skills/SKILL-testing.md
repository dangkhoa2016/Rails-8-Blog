# SKILL-testing.md

> Read this when: writing RSpec specs, factories, stubs, or setting up CI.

## Framework

- RSpec (not Minitest), FactoryBot, SimpleCov (min 90%), WebMock, shoulda-matchers

## Key RSpec Config

SimpleCov MUST be required first (before any other requires).

Includes: FactoryBot::Syntax::Methods, Devise::Test::IntegrationHelpers (request specs)
Before each: stub_cloudinary_requests, WebMock.disable_net_connect!(allow_localhost: true)

## Cloudinary Stubs

Always call stub_cloudinary_requests in before(:each). It stubs:
- POST cloudinary.com/upload -> { public_id, secure_url, width, height }
- DELETE cloudinary.com/resources -> { deleted: {} }
- POST cloudinary.com/rename -> { public_id: new_id }

## Factory Conventions

Users: always set confirmed_at: Time.current (unless testing unconfirmed flow)
Traits: :admin, :author, :unconfirmed
Password: Password123!

Posts: use :with_translations trait to set title/slug for all 7 locales
Use Mobility.with_locale(locale) { ... } inside after(:build)
Trait :published sets status: published, published_at: 1.hour.ago

## Testing Multilingual

  Mobility.with_locale(:vi) { post.title = "Tieu de" }
  get "/api/v1/posts", headers: { "Accept-Language" => "vi" }

## Testing JWT Auth

  post "/api/v1/auth/sign_in", params: { user: { email: user.email, password: "Password123!" } }
  token = response.headers["Authorization"]
  get "/api/v1/profile", headers: { "Authorization" => token }

## Testing Jobs

  expect(PublishPostJob).to have_been_enqueued.with(post.id)
  use queue_adapter = :test in test environment

## CI Order

1. RuboCop
2. RSpec
3. SimpleCov check (fail if < 90%)

Required CI ENV: RAILS_ENV=test, REDIS_URL=redis://localhost:6379/0,
DEVISE_JWT_SECRET_KEY=any_string, CLOUDINARY_* = test

## Common Pitfalls

- SimpleCov require order matters -- must be first.
- Always stub Cloudinary or WebMock will raise errors on any upload attempt.
- confirmed_at must be set in user factories or Devise blocks sign-in.
- Mobility.with_locale needed to set/read translations in specs.
- Use :test queue adapter + have_been_enqueued matcher for job assertions.
