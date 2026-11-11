# Human Real-World Acceptance Checklist

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](HUMAN_TESTING.vi.md)

Use this checklist to verify the user experience and functional behavior of a specific deployment. Automated CI covers source-level checks, while browser and operational behavior depend on the environment.

## Preparation

Use an isolated test account and disposable content on the test deployment. Record commit SHA, test environment, browser, locale, timestamp and screenshots without private data. Do not run destructive scenarios against real production data.

## Scenarios

- [ ] Register, confirm, sign in, reset password and sign out via web.
- [ ] API sign-in issues a bearer token; first sign-out revokes it; reused/missing tokens return 401; other protected endpoints reject revoked JWT.
- [ ] Compare admin, author, reader and guest access; verify unauthorized actions are blocked.
- [ ] Create, edit, preview, publish, schedule and soft-delete posts.
- [ ] Verify unpublished, future and discarded posts remain inaccessible publicly and through the API.
- [ ] Edit and view all seven locales; test localized slug changes and fallback behavior.
- [ ] Upload ActionText images and slides; check R2-original and Cloudinary-derived boundaries.
- [ ] Create, reorder, localize and delete slideshow items.
- [ ] Test comments, reactions, categories and tags.
- [ ] Test security throttling, maintenance settings, audit history and restoration permissions.
- [ ] Restart the container and verify DB-backed state and jobs persist; do not assume local disk persistence.
- [ ] Exercise relevant mobile and desktop browsers, keyboard and accessibility basics.

## Recording outcomes

For each scenario, mark PASS/FAIL/NOT RUN and record evidence and any issue link. Retest fixes and re-run targeted/full regressions. **Do not claim human acceptance complete until these journeys are actually executed.**

Test records apply only to their environment and source SHA. See [limitations](LIMITATIONS.md) and [deployment guide](DEPLOYMENT.md).
