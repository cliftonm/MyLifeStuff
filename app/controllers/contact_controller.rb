require 'html_dsl'
require 'html_generator'

include ApplicationHelper
include Airity
include StyleHelper

class ContactController < ApplicationController
  before_filter :authenticate_user

  # TODO: Filter by category
  # TODO: Show assigned categories
  def show
    @styles = AppStyles.new()
    @page_style = @styles.css.html_safe

    contacts = Contact.where("user_id=#{session[:user_id]}").order('first_name ASC')
    html_dsl = HtmlDsl.new()
    html_dsl.form("contact", {id: 'contact_form', action: 'contact', authenticity_token: form_authenticity_token}) do

      # Contacts table
      html_dsl.div() do
        contact_html = create_contact_table(contacts)
        html_dsl.inject(contact_html)
      end

      # Managing contacts
      html_dsl.div({classes: [@styles.inline_div]}) do
        create_contact_management(html_dsl)
      end

      # Selecting categories
      html_dsl.div({classes: [@styles.inline_div]}) do
        show_categories(html_dsl)
      end

      html_dsl.div({classes: [@styles.clear_both]}) {}

      html_dsl.line_break()
      html_dsl.label('CSV to Import:')
      html_dsl.line_break()
      html_dsl.text_area({field_name: 'import_text', rows: '10', columns: '80'})
      html_dsl.line_break()
      html_dsl.post_button('Import')
    end

    @contact_html = get_html(html_dsl.html_gen.xdoc).html_safe

    nil
  end

  def post
    # Ex: Convert "Delete Selected" to "delete_selected"
    method_name = params[:commit].downcase.gsub(' ', '_')
    method(method_name).call(params)
    redirect_to :contacts

    nil
  end

  def import

    nil
  end

  private

  def add(params)
    params[:contact].delete(:import_text)     # This field is not part of the contact model.
    contact = Contact.new({user_id: session[:user_id]}.merge(params[:contact]))
    contact.save()

    # save associated categories.
    # TODO: Duplicate code.  See below.  Also see other controllers.
    if params[:category_list]
      params[:category_list].each do |cat|
        # One way to do this, if id's are exposed as attr_accessible:
        # contact_cat = ContactCategory.new({category_id: get_record_id(cat), contact_id: contact.id })
        # Or, by assigning the FK objects, which is probably better because the FK objects could then be referenced.
        contact_cat = ContactCategory.new()
        contact_cat.contact = contact
        contact_cat.category = Category.find(get_record_id(cat))
        contact_cat.save()
      end
    end

    nil
  end

  def update_selected(params)
    if one_and_only_one_selection(params)
      params[:contact].delete(:import_text)     # This field is not part of the contact model.
      record_id = get_record_id(params[:contact_list].first)
      contact = Contact.find(record_id)
      # TODO: IMPLEMENT!
      # contact.name = params[:contact][:name]
      contact.save()

      # update selected categories
      contact.categories.delete_all()                # delete all associated categories
      # recreate the associated categories
      # TODO: Duplicate code.  See above.  Also see other controllers.
      if params[:category_list]
        params[:category_list].each do |cat|
          # One way to do this, if id's are exposed as attr_accessible:
          # contact_cat = ContactCategory.new({category_id: get_record_id(cat), contact_id: contact.id })
          # Or, by assigning the FK objects, which is probably better because the FK objects could then be referenced.
          contact_cat = ContactCategory.new()
          contact_cat.contact = contact
          contact_cat.category = Category.find(get_record_id(cat))
          contact_cat.save()
        end
      end

    else
      flash[:notice] = 'Please select one and only one contact as the contact to update.'
    end

    nil
  end

  def delete_selected(params)
    # TODO: Effectively duplicate code between controllers.
    if params[:contact_list]
      params[:contact_list].each do |record|
        record_id = get_record_id(record)
        Contact.destroy(record_id)          # use destroy to force cascading deletes.

      end
    else
      flash[:notice] = 'Nothing to delete.  Please check one or more contacts to delete first.'
    end

    nil
  end

  # TODO: Website should be a link!  See note on having a field dictionary that specifies the "control" used to display the data.
  def create_contact_table(contacts, options={})
    opts = {show_checkbox_for_row: true}.merge(options)
    contact_html = create_table_view(contacts, 'contact_list', ['first_name', 'last_name', 'home_phone', 'work_phone', 'cell_phone', 'email', 'address', 'website'], opts)

    contact_html
  end

  # TODO: Replace with some better way of presenting these options, for example, right-clicking.
  # TODO: See here:  http://www.jquery4u.com/menus/right-click-context-menu-plugins/ or here: http://www.tweego.nl/jeegoocontext (the latter looking preferable)
  def create_contact_management(html_dsl)
    html_dsl.div() do
      create_edit_boxes_for(html_dsl, ['first_name', 'last_name', 'home_phone', 'work_phone', 'cell_phone', 'email', 'address', 'website'])
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
      html_dsl.text_field({field_name: field, autocomplete: false})
      html_dsl.line_break()
    end
  end

  # return true if there is only one selection.  False for 0 or more than 1 selection.
  def one_and_only_one_selection(params)
    params[:contact_list] && params[:contact_list].count == 1
  end
end
