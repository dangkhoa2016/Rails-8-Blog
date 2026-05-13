module Admin
  class UsersController < AdminController
    before_action :set_user, only: [ :show, :edit, :update, :destroy ]

    def index
      @pagy, @users = pagy(User.all)
    end

    def show
      authorize @user
    end

    def new
      @user = User.new
      authorize @user
    end

    def create
      @user = User.new(user_params)
      authorize @user

      if @user.save
        redirect_to admin_users_path, notice: t("admin.users.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @user
    end

    def update
      authorize @user

      if @user.update(user_params)
        redirect_to admin_users_path, notice: t("admin.users.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @user
      @user.destroy
      redirect_to admin_users_path, notice: t("admin.users.destroyed")
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      permitted = [ :email, :full_name, :password, :password_confirmation ]
      permitted << :role if current_user.admin?
      params.require(:user).permit(permitted)
    end
  end
end
