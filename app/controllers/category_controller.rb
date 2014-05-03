require 'html_dsl'
require 'html_generator'

include ApplicationHelper
include Airity

class CategoryController < ApplicationController
  before_filter :authenticate_user

  def show
    @categories = Category.where('category_id is null').order('name ASC')
    html_dsl = HtmlDsl.new()
    html_dsl.form("category", {id: 'category_form', action: 'category', authenticity_token: form_authenticity_token}) do
      create_category_table(html_dsl)
      create_category_management(html_dsl)
    end
    @category_html = get_html(html_dsl.html_gen.xdoc).html_safe

    nil
  end

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
      record_id = get_record_id(params[:table].first)
      cat = Category.new({name: params[:category][:name], user_id: session[:user_id], category_id: record_id})
      cat.save()
    else
      flash[:notice] = 'Please select one and only one category as the parent category.'
    end

    nil
  end

  def update_selected(params)
    if one_and_only_one_selection(params)
      record_id = get_record_id(params[:table].first)
      cat = Category.find(record_id)
      cat.name = params[:category][:name]
      cat.save()
    else
      flash[:notice] = 'Please select one and only one category as the parent category.'
    end

    nil
  end

  def delete_selected(params)
    if params[:table]
      params[:table].each do |record|
        record_id = get_record_id(record)
        Category.delete(record_id)
      end
    else
      flash[:notice] = 'Nothing to delete.  Please check some categories first.'
    end

    nil
  end

  def create_category_table(html_dsl)
    html_dsl.div() do
      category_html = create_table_view(@categories, ["name"], {show_checkboxes: true})
      html_dsl.inject(category_html)
    end

    nil
  end

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
    params[:table] && params[:table].count == 1
  end

  # parse the "record_[n]" string and return only [n]
  def get_record_id(record)
    record[0].partition('_').last.to_i
  end
end
