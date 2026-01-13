# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController

  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  def create
    email = resource_params[:email].to_s.strip

    if email.present?
      user = resource_class.find_by(email: email)
      if user&.provider == "google_oauth2"
        self.resource = resource_class.new(email: email)
        resource.errors.add(:base, I18n.t("devise.passwords.google_oauth2"))
        return render :new, status: :unprocessable_entity
      end
    end

    super
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
