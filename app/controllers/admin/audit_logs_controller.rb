module Admin
  class AuditLogsController < AdminController
    def index
      @blocked_logs = BlockedRequestLog.recent
      @blocked_logs = @blocked_logs.by_ip(params[:ip]) if params[:ip].present?
      @blocked_logs = @blocked_logs.by_reason(params[:reason]) if params[:reason].present?
      @pagy, @blocked_logs = pagy(@blocked_logs, items: 50)

      @versions = PaperTrail::Version.order(created_at: :desc)
      @versions = @versions.where(whodunnit: params[:user_id].to_s) if params[:user_id].present?
      @versions = @versions.where(item_type: params[:item_type]) if params[:item_type].present?
      @versions = @versions.limit(100)
    end

    def show
      @version = PaperTrail::Version.find(params[:id])
    end
  end
end
