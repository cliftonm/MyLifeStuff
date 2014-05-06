require 'html_dsl'
require 'html_generator'

include ApplicationHelper
include Airity
include StyleHelper

class NoteController < ApplicationController
  before_filter :authenticate_user

  def initialize()
    super()
    @note_fields = ['subject', 'note']
  end

  # TODO: Filter by category
  # TODO: Show assigned categories
  # TODO: (And other controllers) scroll selection to top.  See http://jsfiddle.net/SZKJh/1/, change calculation to: row.offset().top-row.height()
  def show
    @styles = AppStyles.new()
    @page_style = @styles.css.html_safe

    notes = Note.where("user_id=#{session[:user_id]}").order('subject ASC')
    html_dsl = HtmlDsl.new()
    html_dsl.form("note", {id: 'note_form', action: 'note', authenticity_token: form_authenticity_token}) do

      # Notes table
      # This table is interesting in that I put the scrollbar on the left by fussing with the rtl and ltr direction style of the div and table.
      html_dsl.div({classes: [@styles.scrollable_div300]}) do
        note_html = create_note_table(notes, {class: 'note-table', one_column_per_row: true})
        html_dsl.inject(note_html)
      end

      # Fill remaining space to the right.
      html_dsl.div({classes: [@styles.div_fill]}) {}

      # Managing notes
      html_dsl.div({classes: [@styles.inline_div]}) do
        create_note_management(html_dsl)
      end

      # Selecting categories
      html_dsl.div({classes: [@styles.inline_div]}) do
        show_categories(html_dsl)
      end

      html_dsl.div({classes: [@styles.clear_both]}) {}
    end

    @note_html = get_html(html_dsl.html_gen.xdoc).html_safe

    nil
  end

  def post
    # Ex: Convert "Delete Selected" to "delete_selected"
    method_name = params[:commit].downcase.gsub(' ', '_')
    method(method_name).call(params)
    redirect_to :notes

    nil
  end

  private

  def add(params)
    note = Note.new({user_id: session[:user_id]}.merge(params[:note]))
    note.save()

    # save associated categories.
    # TODO: Duplicate code.  See below.  Also see other controllers.
    if params[:category_list]
      params[:category_list].each do |cat|
        # One way to do this, if id's are exposed as attr_accessible:
        # note_cat = NoteCategory.new({category_id: get_record_id(cat), note_id: note.id })
        # Or, by assigning the FK objects, which is probably better because the FK objects could then be referenced.
        note_cat = NoteCategory.new()
        note_cat.note = note
        note_cat.category = Category.find(get_record_id(cat))
        note_cat.save()
      end
    end

    nil
  end

  def update_selected(params)
    if one_and_only_one_selection(params)
      params[:note].delete(:import_text)     # This field is not part of the note model.
      record_id = get_record_id(params[:note_list].first)
      note = Note.find(record_id)
                                                # TODO: IMPLEMENT!
                                                # note.name = params[:note][:name]
      note.save()

      # update selected categories
      note.categories.delete_all()                # delete all associated categories
      # recreate the associated categories
      # TODO: Duplicate code.  See above.  Also see other controllers.
      if params[:category_list]
        params[:category_list].each do |cat|
          # One way to do this, if id's are exposed as attr_accessible:
          # note_cat = NoteCategory.new({category_id: get_record_id(cat), note_id: note.id })
          # Or, by assigning the FK objects, which is probably better because the FK objects could then be referenced.
          note_cat = NoteCategory.new()
          note_cat.note = note
          note_cat.category = Category.find(get_record_id(cat))
          note_cat.save()
        end
      end

    else
      flash[:notice] = 'Please select one and only one note as the note to update.'
    end

    nil
  end

  def delete_selected(params)
    # TODO: Effectively duplicate code between controllers.
    if params[:note_list]
      params[:note_list].each do |record|
        record_id = get_record_id(record)
        Note.destroy(record_id)          # use destroy to force cascading deletes.

      end
    else
      flash[:notice] = 'Nothing to delete.  Please check one or more notes to delete first.'
    end

    nil
  end

  # TODO: Website should be a link!  See note on having a field dictionary that specifies the "control" used to display the data.
  def create_note_table(notes, options={})
    opts = {show_checkbox_for_row: true}.merge(options)
    note_html = create_table_view(notes, 'note_list', @note_fields, opts)

    note_html
  end

  # TODO: Replace with some better way of presenting these options, for example, right-clicking.
  # TODO: See here:  http://www.jquery4u.com/menus/right-click-context-menu-plugins/ or here: http://www.tweego.nl/jeegoocontext (the latter looking preferable)
  def create_note_management(html_dsl)
    html_dsl.div() do
      create_edit_boxes_for(html_dsl, @note_fields)
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
  # TODO: Duplicate code in most controllers.
  def show_categories(html_dsl)
    categories = Category.where("user_id = #{session[:user_id]} and category_id is null").order('name ASC')
    category_html = create_category_table(categories)
    html_dsl.inject(category_html)
  end

  def create_edit_boxes_for(html_dsl, fields)
    fields.each do |field|
      # TODO: Provide a mechanism (like a field dictionary) to specify the implementing control and label text.  See Airity demo.
      if field=='note'
        html_dsl.label("#{field.gsub('_', ' ').capitalize}:")
        html_dsl.text_area({field_name: 'note', id: 'note_control', rows: '10', columns: '80'})
      else
        html_dsl.label("#{field.gsub('_', ' ').capitalize}:", {classes: [@styles.input_label]})
        html_dsl.text_field({field_name: field, autocomplete: false})
      end

      html_dsl.line_break()
    end
  end

  # return true if there is only one selection.  False for 0 or more than 1 selection.
  def one_and_only_one_selection(params)
    params[:note_list] && params[:note_list].count == 1
  end
end
