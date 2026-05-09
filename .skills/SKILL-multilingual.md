# SKILL-multilingual.md — Multilingual Content (Mobility + i18n)

> Read this when: working on Mobility translations, locale routing, multilingual admin UI, or content display.

---

## Language Split

| Surface | Locales |
|---|---|
| Admin UI / Rails I18n (YAML) | `en`, `vi` |
| Post content / Frontend | `en`, `vi`, `ru`, `ja`, `ko`, `th`, `de` |

```ruby
# config/application.rb
config.i18n.available_locales = [:en, :vi, :ru, :ja, :ko, :th, :de]
config.i18n.default_locale = :en
config.i18n.fallbacks = true
```

---

## Mobility: What It Translates

Mobility translates **two string fields** on `Post`:
- `title` — the post headline
- `slug` — the URL-safe identifier

These live in the `post_translations` table (not on `posts`).

```ruby
# app/models/post.rb
extend Mobility
translates :title, :slug, backend: :table
```

Rich text **content** is NOT translated by Mobility. Instead, separate ActionText fields are used per locale:
```ruby
has_rich_text :content_en
has_rich_text :content_vi
has_rich_text :content_ru
has_rich_text :content_ja
has_rich_text :content_ko
has_rich_text :content_th
has_rich_text :content_de
```

Access content for current locale:
```ruby
post.content_for(I18n.locale)  # calls post.send(:"content_#{locale}")
```

---

## Mobility Configuration

```ruby
# config/initializers/mobility.rb
Mobility.configure do |config|
  config.plugins do
    backend :table
    active_record
    reader; writer
    fallbacks({ vi: :en, ru: :en, ja: :en, ko: :en, th: :en, de: :en })
    presence; cache; dirty; column_fallback
  end
end
```

All non-English locales fall back to English. This means if a Japanese translation is missing, `post.title` (when `I18n.locale = :ja`) returns the English title.

---

## post_translations Table Structure

```ruby
create_table :post_translations do |t|
  t.references :post, null: false, foreign_key: true
  t.string :locale, null: false
  t.string :title
  t.string :slug
  t.timestamps
end
add_index :post_translations, [:post_id, :locale], unique: true
add_index :post_translations, :slug
```

---

## FriendlyId + Mobility

```ruby
extend FriendlyId
friendly_id :title, use: [:mobility, :history]
```

This generates a slug from the title **for each locale separately**. So `/en/posts/hello-world` and `/vi/posts/xin-chao` both work and point to the same post.

Finding by slug in controllers:
```ruby
Post.friendly.find(params[:slug])
```

---

## URL Routing

```ruby
# config/routes.rb
scope '/:locale', locale: /en|vi|ru|ja|ko|th|de/ do
  resources :posts, param: :slug, only: [:index, :show]
  resources :categories, param: :slug, only: [:index, :show]
  resources :tags, param: :slug, only: [:index, :show]
end
```

Locale is in the **URL path**, not a query param. URL examples:
- `/en/posts/hello-world`
- `/vi/posts/xin-chao`
- `/ja/posts/nihongo-title`

---

## Setting the Locale (ApplicationController)

```ruby
def set_locale
  locale = params[:locale] || session[:locale] || I18n.default_locale
  I18n.locale = I18n.available_locales.include?(locale.to_sym) ? locale : I18n.default_locale
end
```

For the API, locale comes from:
1. `Accept-Language` request header
2. `?locale=` query param
3. Falls back to `:en`

---

## Admin UI: Language Tabs (Stimulus)

The admin post form has a tab per locale. Switching tabs does NOT reload the page.

Controller: `language-tabs` (in `app/javascript/controllers/language_tabs_controller.js`)

Usage in ERB:
```erb
<div data-controller="language-tabs">
  <div class="tab-list">
    <% I18n.available_locales.each do |locale| %>
      <button data-language-tabs-target="tab"
              data-locale="<%= locale %>"
              data-action="click->language-tabs#switch">
        <%= t("locales.#{locale}") %>
      </button>
    <% end %>
  </div>

  <% I18n.available_locales.each do |locale| %>
    <div data-language-tabs-target="panel" data-locale="<%= locale %>" hidden>
      <%# Title input for this locale %>
      <%# Rich text editor for this locale %>
    </div>
  <% end %>
</div>
```

---

## Setting Translations in FactoryBot

Use `Mobility.with_locale` to set per-locale values:
```ruby
trait :with_translations do
  after(:build) do |post|
    I18n.available_locales.each do |locale|
      Mobility.with_locale(locale) do
        post.title = Faker::Lorem.sentence(word_count: 4)
        post.slug  = post.title.parameterize
      end
    end
  end
end
```

---

## Caching With Locale

**Critical rule**: always include `I18n.locale` in fragment cache keys.

```erb
<% cache [post, I18n.locale, 'card_v1'] do %>
  ...
<% end %>
```

Omitting the locale causes cross-language cache pollution (e.g., a Vietnamese user sees an English cached page).

---

## hreflang Tags (SEO)

In `<head>`, include hreflang links for all locales:
```erb
<% I18n.available_locales.each do |locale| %>
  <% Mobility.with_locale(locale) do %>
    <link rel="alternate" hreflang="<%= locale %>"
          href="<%= url_for(locale: locale, slug: @post.slug) %>" />
  <% end %>
<% end %>
```

---

## Querying with Mobility

Filter posts that have a translation in a given locale:
```ruby
scope :by_locale, ->(locale) {
  joins(:post_translations).where(post_translations: { locale: locale })
}
```

Do not use `where(title: ...)` on Post directly — use `Mobility.with_locale { Post.where(title: ...) }`.

---

## Common Pitfalls

- **Do not put `title` or `slug` directly on `posts` table** — they live in `post_translations`.
- **Rich text per locale is NOT in `post_translations`** — it uses `action_text_rich_texts` with different `name` values.
- **`Post.friendly.find(slug)` uses the current `I18n.locale`** — make sure locale is set before calling this.
- **Fallback doesn't auto-create translations** — if you call `post.title` in Japanese and there's no Japanese translation, it returns the English title but does NOT create a Japanese `PostTranslation` row.
- **Admin YAML only for en/vi** — do not add `ru`, `ja`, `ko`, `th`, `de` to admin translation files.
