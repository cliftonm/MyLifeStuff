require 'html_dsl'
require 'html_generator'

include ApplicationHelper
include Airity

class CategoryController < ApplicationController
  before_filter :authenticate_user

  # TODO: Use a session variable, say ":checked_categories", to preserve selection.
  # TODO: Add the ability to add extra information to the table rendering, for example "checked" for checkboxes added to rows or columns.
  def show
    categories = Category.where("user_id = #{session[:user_id]} and category_id is null").order('name ASC')
    html_dsl = HtmlDsl.new()
    html_dsl.form("category", {id: 'category_form', action: 'category', authenticity_token: form_authenticity_token}) do
      html_dsl.div() do
        category_html = create_category_table(categories)
        html_dsl.inject(category_html)
      end

      create_category_management(html_dsl)
    end

    @category_html = get_html(html_dsl.html_gen.xdoc).html_safe
    # TODO: Nested categories not filling the textbox correctly.
    @javascript = create_row_click_javascript('category', ['name'], 1).html_safe   # javascript for when user clicks on a row to populate edit boxes.

    nil
  end

  # TODO: Review "advanced contraints" to see if this could be better handled by declaring the routes:
  # http://stackoverflow.com/questions/3332449/rails-multi-submit-buttons-in-one-form
  # Conversely, maybe use link_to and change the styling so it looks like a button?
  def post
    # Ex: Convert "Delete Selected" to "delete_selected"
    method_name = params[:commit].downcase.gsub(' ', '_')
    method(method_name).call(params)
    redirect_to :categories

    nil
  end

  private

  def add(params)
    cat = Category.new({name: params[:category][:name], user_id: session[:user_id]})
    cat.save()

    nil
  end

  def add_as_child_of_selected(params)
    if one_and_only_one_selection(params)
      record_id = get_record_id(params[:category_list].first)
      cat = Category.new({name: params[:category][:name], user_id: session[:user_id], category_id: record_id})
      cat.save()
    else
      flash[:notice] = 'Please select one and only one category as the parent category.'
    end

    nil
  end

  def update_selected(params)
    if one_and_only_one_selection(params)
      record_id = get_record_id(params[:category_list].first)
      cat = Category.find(record_id)
      cat.name = params[:category][:name]
      cat.save()
    else
      flash[:notice] = 'Please select one and only one category as the category to update.'
    end

    nil
  end

  def delete_selected(params)
    if params[:category_list]
      params[:category_list].each do |record|
        record_id = get_record_id(record)
        Category.destroy(record_id)                 # use destroy to force cascading deletes.
      end
    else
      flash[:notice] = 'Nothing to delete.  Please check one or more categories to delete first.'
    end

    nil
  end

  # TODO: Replace with some better way of presenting these options, for example, right-clicking.
  # TODO: See here:  http://www.jquery4u.com/menus/right-click-context-menu-plugins/ or here: http://www.tweego.nl/jeegoocontext (the latter looking preferable)
  def create_category_management(html_dsl)
    html_dsl.div() do
      html_dsl.label('Category Name:')
      html_dsl.text_field({field_name: 'name'})
      html_dsl.line_break()
      html_dsl.post_button('Add')
      html_dsl.post_button('Add as Child of Selected')
      html_dsl.line_break()
      html_dsl.post_button('Update Selected')
      html_dsl.line_break()
      html_dsl.post_button('Delete Selected')
    end

    nil
  end

  # return true if there is only one selection.  False for 0 or more than 1 selection.
  def one_and_only_one_selection(params)
    params[:category_list] && params[:category_list].count == 1
  end
end
