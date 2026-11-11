# Interface Walkthrough

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](INTERFACE_WALKTHROUGH.vi.md)

Explore the localized public website, account flows and publishing interface using a locally running Rails 8 Blog instance and disposable test data.

## 1. Public site

Open `http://localhost:3000/en` or `http://localhost:3000/vi`. Browse `/en/posts` or `/vi/posts` and open a published article. Review its localized title, rich-text content and available slideshow. Switch languages to check the selected translation and URL.

## 2. Accounts and permissions

Visit `/en/auth/sign_in` or `/vi/auth/sign_in` and sign in with a test account. Compare reader, author and administrator permissions using separate sessions. Registration, confirmation and password-reset workflows require email delivery configuration.

## 3. Editor and administration

An authorized administrator can open `/en/admin` and `/en/admin/posts`. Create and edit post titles, slugs and rich-text content in multiple languages. Check preview, publication scheduling, soft deletion and slideshow ordering. Other roles can access only the actions permitted by their policies.

## 4. Mobile and accessibility

Repeat representative journeys at mobile and desktop widths. Use the keyboard to switch tabs and menus, check visible focus, inspect image alternative text and verify that validation errors are announced clearly.

## 5. API examples

Use [api-demo.http](api-demo.http) with the [API guide](API.md) to exercise health, public content and authenticated JWT requests.

See the [manual testing checklist](HUMAN_TESTING.md) for a structured acceptance procedure and the [asset provenance inventory](ASSET_PROVENANCE.md) for bundled media rights.
