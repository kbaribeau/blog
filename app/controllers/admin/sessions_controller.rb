class Admin::SessionsController < ApplicationController
  layout 'login'
  GOOGLE_OPENID_URL = 'https://www.google.com/accounts/o8/id'
  
  def show
    params[:openid_url] = GOOGLE_OPENID_URL
    create
  end

  def create
    authenticate_with_open_id(params[:openid_url]) do |result, identity_url|
      if result.successful?
        if enki_config.author_open_ids.include?(URI.parse(identity_url))
          return successful_login
        else
          flash.now[:error] = result.message
        end
      else
        flash.now[:error] = result.message
      end
      render :action => 'new'
    end
  end

  def destroy
    session[:logged_in] = false
    redirect_to('/')
  end

protected

  def successful_login
    session[:logged_in] = true
    redirect_to(admin_root_path)
  end
end
