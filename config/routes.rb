MyLifeStuff::Application.routes.draw do
  root :to=>"home#index"
  get "signed_out" => "authentication#signed_out"
  get "forgot_password" => "authentication#forgot_password"
  get "password_sent" => "authentication#password_sent"

  get "sign_in" => "authentication#sign_in"
  post "sign_in" => "authentication#login"

  get "new_user" => "authentication#new_user"
  post "new_user" => "authentication#register"

  get "account_settings" => "authentication#account_settings"
  put "account_settings" => "authentication#set_account_info"

  get "forgot_password" => "authentication#forgot_password"
  put "forgot_password" => "authentication#send_password_reset_instructions"
  get "password_reset" => "authentication#password_reset"
  put "password_reset" => "authentication#new_password"

  get "admin_users" => "admin#users"
  delete "user/:id" => "admin#delete_user", :as => "user"

  # ===========================

  get "categories" => "category#show"
  post "category" => "category#post"

  get "accounts" => "account#show"
  post "account" => "account#post"
end
