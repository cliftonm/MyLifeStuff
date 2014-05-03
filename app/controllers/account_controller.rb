require 'html_dsl'
require 'html_generator'

include ApplicationHelper
include Airity
include StyleHelper

class AccountController < ApplicationController
  before_filter :authenticate_user

  def show
    @styles = AppStyles.new()
    @page_style = @styles.css.html_safe

    accounts = Account.where("user_id=#{session[:user_id]}").order('name ASC')
    html_dsl = HtmlDsl.new()
    html_dsl.form("account", {id: 'account_form', action: 'account', authenticity_token: form_authenticity_token}) do

      # Display options
      html_dsl.div() do
        html_dsl.checkbox('display_all', 'Display all fields (Passwords will appear in plain text!)', {value: get_checked(session[:display_all])})
        html_dsl.post_button('Update View')
      end

      # Accounts table
      html_dsl.div() do
        account_html = create_account_table(accounts)
        html_dsl.inject(account_html)
      end

      # Managing accounts
      html_dsl.div({classes: [@styles.inline_div]}) do
        create_account_management(html_dsl)
      end

      # Selecting categories
      html_dsl.div({classes: [@styles.inline_div]}) do
        show_categories(html_dsl)
      end

      html_dsl.div({classes: [@styles.clear_both]}) {}
    end

    @account_html = get_html(html_dsl.html_gen.xdoc).html_safe

    nil
  end

  def post
    # Ex: Convert "Delete Selected" to "delete_selected"
    method_name = params[:commit].downcase.gsub(' ', '_')
    method(method_name).call(params)
    redirect_to :accounts

    nil
  end

  private

  def add(params)
    encrypt_password(params)
    params[:account].delete(:display_all)     # This field is not part of the account model.
    acct = Account.new({user_id: session[:user_id]}.merge(params[:account]))
    acct.save()

    # save associated categories.
    if params[:category_list]
      params[:category_list].each do |cat|
        # One way to do this, if id's are exposed as attr_accessible:
        # acct_cat = AccountCategory.new({category_id: get_record_id(cat), account_id: acct.id })
        # Or, by assigning the FK objects, which is probably better because the FK objects could then be referenced.
        acct_cat = AccountCategory.new()
        acct_cat.account = acct
        acct_cat.category = Category.find(get_record_id(cat))
        acct_cat.save()
      end
    end

    nil
  end

  def update_selected(params)
    if one_and_only_one_selection(params)
      record_id = get_record_id(params[:account_list].first)
      acct = Account.find(record_id)
      # TODO: IMPLEMENT!
      # acct.name = params[:account][:name]
      acct.save()

      # update selected categories
      acct.categories.delete_all()                # delete all associated categories
      # recreate the associated categories
      if params[:category_list]
        params[:category_list].each do |cat|
          # One way to do this, if id's are exposed as attr_accessible:
          # acct_cat = AccountCategory.new({category_id: get_record_id(cat), account_id: acct.id })
          # Or, by assigning the FK objects, which is probably better because the FK objects could then be referenced.
          acct_cat = AccountCategory.new()
          acct_cat.account = acct
          acct_cat.category = Category.find(get_record_id(cat))
          acct_cat.save()
        end
      end

    else
      flash[:notice] = 'Please select one and only one account as the account to update.'
    end

    nil
  end

  def delete_selected(params)
    if params[:account_list]
      params[:account_list].each do |record|
        record_id = get_record_id(record)
        Account.destroy(record_id)          # use destroy to force cascading deletes.

      end
    else
      flash[:notice] = 'Nothing to delete.  Please check one or more accounts to delete first.'
    end

    nil
  end

  def update_view(params)
    session[:display_all] = !!params[:account][:display_all]     # !! because !nil is true, and !!nil is false.  #same as !...nil?
  end

  # custom text renderer for the password.
  def decrypt_password(pwd)
    user = User.find(session[:user_id])
    iv = Rails.configuration.iv    # see secret_token.rb
    Encryptor.decrypt(value: Base64.decode64(pwd.encode('ascii-8bit')), key: user.password_hash, iv: iv, salt: user.password_salt)
  end

  # TODO: URL should be a link!  See note on having a field dictionary that specifies the "control" used to display the data.
  def create_account_table(accounts, options={})
    opts = {show_checkbox_for_row: true}.merge(options)

    if session[:display_all]
      # custom text renderer for the password.
      opts.merge!({custom_text_renderers: {password: lambda(&method(:decrypt_password))}})

      # Alternatively, we could define a proc:
      # decrypt_password = Proc.new do |pwd|
      #   user = User.find(session[:user_id])
      #   iv = Rails.configuration.iv    # see secret_token.rb
      #   Encryptor.decrypt(value: Base64.decode64(pwd.encode('ascii-8bit')), key: user.password_hash, iv: iv, salt: user.password_salt)
      # end
      # And call specify the renderer this way:
      # opts.merge!({custom_text_renderers: {password: decrypt_password}})

      account_html = create_table_view(accounts, 'account_list', ["name", 'acct_number', 'url', 'due_on', 'notes', 'username', 'password'], opts)
    else
      account_html = create_table_view(accounts, 'account_list', ["name", 'url', 'due_on', 'notes'], opts)
    end

    account_html
  end

  # TODO: Replace with some better way of presenting these options, for example, right-clicking.
  # TODO: See here:  http://www.jquery4u.com/menus/right-click-context-menu-plugins/ or here: http://www.tweego.nl/jeegoocontext (the latter looking preferable)
  def create_account_management(html_dsl)
    html_dsl.div() do
      create_edit_boxes_for(html_dsl, ['name', 'url', 'username', 'password', 'acct_number', 'due_on', 'notes'])
      html_dsl.line_break()
      html_dsl.post_button('Add')
      html_dsl.line_break()
      html_dsl.post_button('Update Selected')
      html_dsl.line_break()
      html_dsl.post_button('Delete Selected')
    end

    nil
  end

  # TODO: Replace with a real tree-view, rather than one generated from nested tables.
  def show_categories(html_dsl)
    categories = Category.where("user_id = #{session[:user_id]} and category_id is null").order('name ASC')
    category_html = create_category_table(categories)
    html_dsl.inject(category_html)
  end

  def create_edit_boxes_for(html_dsl, fields)
    fields.each do |field|
      html_dsl.label("#{field.gsub('_', ' ').capitalize}:", {classes: [@styles.input_label]})

      # TODO: Provide a mechanism (like a field dictionary) to specify the inplementing control and label text.  See Airity demo.
      if field=='password'
         html_dsl.password_field({field_name: field, autocomplete: false})
      else
        html_dsl.text_field({field_name: field, autocomplete: false})
      end
      html_dsl.line_break()
    end
  end

  # return true if there is only one selection.  False for 0 or more than 1 selection.
  def one_and_only_one_selection(params)
    params[:account_list] && params[:account_list].count == 1
  end

  def encrypt_password(params)
    password = params[:account][:password]

    unless password.blank?                # if a password has been specified, encrypt it...
      #TODO: update this so it uses a public/private key that has been set up on the user's machine or some other mechanism such that the decryption can only occur with something the user provides locally.
      user = User.find(session[:user_id])
      iv = Rails.configuration.iv    # see secret_token.rb
      enc_pwd = Encryptor.encrypt(value: password, key: user.password_hash, iv: iv, salt: user.password_salt)
      enc_pwd2 = Base64.encode64(enc_pwd).encode('utf-8')       # convert to UTF-8 so it's compatible with database string.  Probably not necessary if we used a binary data type.
      params[:account][:password] = enc_pwd2

      # to decode:
      # Encryptor.decrypt(value: Base64.decode64(enc_pwd2.encode('ascii-8bit')), key: user.password_hash, iv: iv, salt: user.password_salt)
    end
  end
end