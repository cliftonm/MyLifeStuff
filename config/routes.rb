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

  get "contacts" => "contact#show"
  post "contact" => "contact#post"

  get "notes" => "note#show"
  post "note" => "note#post"

  get "tasks" => "task#show"
  post "task" => "task#post"


  get "recipes" => "home#not_implemented"
  get "journal" => "home#not_implemented"
  get "kanban" => "home#not_implemented"
  get "coaching" => "home#not_implemented"    # coaching: NVC, tension, how/why/why, facilitated journaling
  get "calendar" => "home#not_implemented"
  get "time" => "home#not_implemented"        # time tracker

  get "test" => "home#test"
  get "my_pages" => "home#my_pages"
  post "my_pages" => "home#my_pages_post"

end
