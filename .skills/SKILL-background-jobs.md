# SKILL-background-jobs.md

> Read this when: writing Sidekiq jobs, scheduling, or reviewing job patterns.

## Queues (priority order, highest first)

| Queue | Jobs |
|---|---|
| critical | AdminNotificationJob |
| default | PublishPostJob |
| mailers | ActionMailer deliver_later |
| media | RenameCloudinaryAssetsJob, CloudinaryHousekeepingJob |

## All Jobs

| Job | Queue | Trigger | What it does |
|---|---|---|---|
| PublishPostJob | default | Post scheduled_at changes | Publishes post at scheduled time |
| RenameCloudinaryAssetsJob | media | Post slug changes | Updates Cloudinary + ActionText URLs |
| CloudinaryHousekeepingJob | media | Cron: Sun 3AM | Deletes orphaned Cloudinary assets |
| AdminNotificationJob | critical | Rack::Attack block | Emails all admins about security event |

## Job Writing Rules

1. Always check record still exists: post = Post.find_by(id: post_id); return unless post
2. Check state is still valid (idempotency): return unless post.scheduled?
3. Pass IDs, not AR objects: PublishPostJob.perform_later(post.id)
4. All jobs inherit from ApplicationJob

## Scheduling

Delayed enqueue:
  PublishPostJob.set(wait_until: post.scheduled_at).perform_later(post.id)

Recurring (config/sidekiq.yml):
  :schedule:
    cloudinary_housekeeping:
      cron: "0 3 * * 0"
      class: CloudinaryHousekeepingJob

## PublishPostJob Pattern

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post&.scheduled?
    return if post.scheduled_at > Time.current
    post.update!(status: "published", published_at: Time.current)
  end

## Common Pitfalls

- Never pass AR objects to jobs -- use IDs only.
- Jobs must be idempotent -- Sidekiq retries on failure.
- CloudinaryHousekeepingJob must paginate (max_results: 500) -- never fetch all at once.
- AdminNotificationJob uses deliver_later to avoid blocking Rack::Attack response thread.
- The media queue runs last -- media jobs should not block emails or publishing.
