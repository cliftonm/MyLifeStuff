require 'html_dsl'
require 'html_generator'

include ApplicationHelper
include Airity
include StyleHelper

class ContactController < ApplicationController
  before_filter :authenticate_user

  def initialize
    super()
    @contact_fields = ['first_name', 'last_name', 'home_phone', 'work_phone', 'cell_phone', 'email', 'address', 'website']
  end

  # TODO: Filter by category
  # TODO: Show assigned categories
  # TODO: Lots of things to help the user clean up their contacts: switch first/last name, display specific columns, etc.  See the contact controller I created:    http://marcclifton.wordpress.com/2014/04/26/a-contact-list-viewer-in-ruby-using-jquery-jquery-ui-and-jquery-tablesorter/
  def show
    @styles = AppStyles.new()
    @page_style = @styles.css.html_safe

    contacts = Contact.where("user_id=#{session[:user_id]}").order('first_name ASC')
    html_dsl = HtmlDsl.new()
    html_dsl.form("contact", {id: 'contact_form', action: 'contact', authenticity_token: form_authenticity_token}) do

      # Contacts table
      # This table is interesting in that I put the scrollbar on the left by fussing with the rtl and ltr direction style of the div and table.
      html_dsl.div({classes: [@styles.scrollable_div300]}) do
        contact_html = create_contact_table(contacts, {class: 'contact-table'})
        html_dsl.inject(contact_html)
      end

      # Fill remaining space to the right.
      html_dsl.div({classes: [@styles.div_fill]}) {}

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
      html_dsl.label('CSV to Import (Google Contact export format):')
      html_dsl.line_break()
      html_dsl.text_area({field_name: 'import_text', rows: '10', columns: '80'})
      html_dsl.line_break()
      html_dsl.post_button('Import')
    end

    @contact_html = get_html(html_dsl.html_gen.xdoc).html_safe
    @javascript = create_row_click_javascript('contact', @contact_fields, 2).html_safe   # javascript for when user clicks on a row to populate edit boxes.

    nil
  end

  def post
    # Ex: Convert "Delete Selected" to "delete_selected"
    method_name = params[:commit].downcase.gsub(' ', '_')
    method(method_name).call(params)
    redirect_to :contacts

    nil
  end

  # TODO: specify delimiter and column mapping, specify whether header exists.
  def import(params)
    if lines = params[:contact][:import_text]
      lines = params[:contact][:import_text].gsub("\n", '').split("\r")
      if lines.count >= 2
        header_labels = lines[0].split(',')
        lines.delete_at(0)                        # remove the header

        lines.each do |line|
          fields = line.split(',')                # get fields

          if fields.count >= 5                    # skip blank lines and short data
            name = fields[0].split(' ')           # split name into first name and last name
            first_name = name[0]                  # address books can be a mess, so we're just assuming first name is first.
            last_name = ''                        # Assume no last name is provided.

            # If the name is something like "John Van Burk" then the first name will be "John" and the last name "Van Burk"
            if name.count >= 2
              last_name = name[1..-1].join(' ')     # concat rest of name data.
            end

            # The google contacts export will have phone numbers like this:
            # Home,<home phone #>,
            # Work,<work phone #>,
            # Mobile,<cell phone #>,
            # If there's multiple phone #'s for a category, they will appear as <phone #> ::: <phone #>  (yes, literally " ::: " with the spaces.)
            # Example:
            # Emma,,,Emma,,,,,,,,,,,,,,,,,,,,,,,* My Contacts,,,Home,5183290085,Mobile,5188211924 ::: 8577531441,,,,

            work_phone = get_phone('Work', header_labels, fields)
            home_phone = get_phone('Home', header_labels, fields)
            cell_phone = get_phone('Mobile', header_labels, fields)
            email = fields[header_labels.index('E-mail 1 - Value')]
            website = fields[header_labels.index('Website 1 - Value')]

            contact = Contact.new({user_id: session[:user_id], first_name: first_name, last_name: last_name, home_phone: home_phone, work_phone: work_phone, cell_phone: cell_phone, email: email, website: website})
            contact.save()
          end
        end
      else
        flash[:notice] = 'Please provide some data besides the header to import.'
      end
    else
      flash[:notice] = 'Please provide some data to import.'
    end

    nil
  end

  private

  # Returns the phone number given the type, using the Google+ header export format.
  def get_phone(type, header_labels, fields)
    ret = ''
    phone1_idx = header_labels.index('Phone 1 - Type')
    phone2_idx = header_labels.index('Phone 2 - Type')
    phone3_idx = header_labels.index('Phone 3 - Type')

    if fields[phone1_idx] == type
      ret = fields[phone1_idx + 1]
    elsif fields[phone2_idx] == type
      ret = fields[phone2_idx + 1]
    elsif fields[phone3_idx] == type
      ret = fields[phone3_idx + 1]
    end

    ret
  end

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
    contact_html = create_table_view(contacts, 'contact_list', @contact_fields, [@contact_fields.count()], opts)

    contact_html
  end

  # TODO: Replace with some better way of presenting these options, for example, right-clicking.
  # TODO: See here:  http://www.jquery4u.com/menus/right-click-context-menu-plugins/ or here: http://www.tweego.nl/jeegoocontext (the latter looking preferable)
  def create_contact_management(html_dsl)
    html_dsl.div() do
      create_edit_boxes_for(html_dsl, @contact_fields)
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
