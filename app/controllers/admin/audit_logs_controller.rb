module Admin
  class AuditLogsController < AdminController
    def index
      @blocked_logs = BlockedRequestLog.recent
      @blocked_logs = @blocked_logs.by_ip(params[:ip]) if params[:ip].present?
      @blocked_logs = @blocked_logs.by_reason(params[:reason]) if params[:reason].present?
      
      @pagy, @blocked_logs = pagy(@blocked_logs, items: 50)
    end
  end
end
