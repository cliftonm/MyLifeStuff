require 'html_dsl'
require 'html_generator'

include ApplicationHelper
include Airity
include StyleHelper

# Tasks are a lot like categories!
# Tasks have categories!
class TaskController < ApplicationController
  before_filter :authenticate_user

  # TODO: Use a session variable, say ":checked_tasks", to preserve selection.
  # TODO: Add the ability to add extra information to the table rendering, for example "checked" for checkboxes added to rows or columns.
  # TODO: When user deletes a parent task and its child task (having selected both) an error "can't delete task with id=[n]" occurs.  Same problem with categories (and other recursive implementations.)
  def show
    @styles = AppStyles.new()
    @page_style = @styles.css.html_safe

    tasks = Task.where("user_id = #{session[:user_id]} and task_id is null").order('name ASC')
    html_dsl = HtmlDsl.new()
    html_dsl.form("task", {id: 'task_form', action: 'task', authenticity_token: form_authenticity_token}) do
      html_dsl.div() do
        task_html = create_task_table(tasks)
        html_dsl.inject(task_html)
      end

      html_dsl.div({classes: [@styles.inline_div]}) do
        create_task_management(html_dsl)
      end

      # Selecting categories
      html_dsl.div({classes: [@styles.inline_div]}) do
        show_categories(html_dsl)
      end

      html_dsl.div({classes: [@styles.clear_both]}) {}

    end

    @task_html = get_html(html_dsl.html_gen.xdoc).html_safe

    nil
  end

  # TODO: Review "advanced contraints" to see if this could be better handled by declaring the routes:
  # http://stackoverflow.com/questions/3332449/rails-multi-submit-buttons-in-one-form
  # Conversely, maybe use link_to and change the styling so it looks like a button?
  def post
    # Ex: Convert "Delete Selected" to "delete_selected"
    method_name = params[:commit].downcase.gsub(' ', '_')
    method(method_name).call(params)
    redirect_to :tasks

    nil
  end

  private

  def add(params)
    task = Task.new({name: params[:task][:name], user_id: session[:user_id]})
    task.save()

    # save associated categories.
    # TODO: Duplicate code.  See below.  Also see other controllers.
    if params[:category_list]
      params[:category_list].each do |cat|
        # One way to do this, if id's are exposed as attr_accessible:
        # note_cat = NoteCategory.new({category_id: get_record_id(cat), note_id: note.id })
        # Or, by assigning the FK objects, which is probably better because the FK objects could then be referenced.
        task_cat = TaskCategory.new()
        task_cat.task = task
        task_cat.category = Category.find(get_record_id(cat))
        task_cat.save()
      end
    end

    nil
  end

  def add_as_child_of_selected(params)
    if one_and_only_one_selection(params)
      record_id = get_record_id(params[:task_list].first)
      task = Task.new({name: params[:task][:name], user_id: session[:user_id], task_id: record_id})
      task.save()

      # save associated categories.
      # TODO: Duplicate code.  See below.  Also see other controllers.
      if params[:category_list]
        params[:category_list].each do |cat|
          # One way to do this, if id's are exposed as attr_accessible:
          # note_cat = NoteCategory.new({category_id: get_record_id(cat), note_id: note.id })
          # Or, by assigning the FK objects, which is probably better because the FK objects could then be referenced.
          task_cat = TaskCategory.new()
          task_cat.task = task
          task_cat.category = Category.find(get_record_id(cat))
          task_cat.save()
        end
      end

    else
      flash[:notice] = 'Please select one and only one task as the parent task.'
    end

    nil
  end

  # TODO: Delete (everywhere) needs a confirmation dialog.
  def update_selected(params)
    if one_and_only_one_selection(params)
      record_id = get_record_id(params[:task_list].first)
      task = Task.find(record_id)
      # TODO: IMPLEMENT!
      task.name = params[:task][:name]
      task.save()

      # update selected categories
      task.categories.delete_all()                # delete all associated categories
      # recreate the associated categories
      # TODO: Duplicate code.  See above.  Also see other controllers.
      if params[:category_list]
        params[:category_list].each do |cat|
          # One way to do this, if id's are exposed as attr_accessible:
          # note_cat = NoteCategory.new({category_id: get_record_id(cat), note_id: note.id })
          # Or, by assigning the FK objects, which is probably better because the FK objects could then be referenced.
          task_cat = NoteCategory.new()
          task_cat.note = task
          task_cat.category = Category.find(get_record_id(cat))
          task_cat.save()
        end
      end

    else
      flash[:notice] = 'Please select one and only one task as the task to update.'
    end

    nil
  end

  def delete_selected(params)
    if params[:task_list]
      params[:task_list].each do |record|
        record_id = get_record_id(record)
        Task.destroy(record_id)                 # use destroy to force cascading deletes.
      end
    else
      flash[:notice] = 'Nothing to delete.  Please check one or more tasks to delete first.'
    end

    nil
  end

  # TODO: Replace with some better way of presenting these options, for example, right-clicking.
  # TODO: See here:  http://www.jquery4u.com/menus/right-click-context-menu-plugins/ or here: http://www.tweego.nl/jeegoocontext (the latter looking preferable)
  def create_task_management(html_dsl)
    html_dsl.div() do
      html_dsl.label('Task Name:')
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
    params[:task_list] && params[:task_list].count == 1
  end

  # TODO: Replace with a real tree-view, rather than one generated from nested tables.
  # TODO: Duplicate code in most controllers.
  def show_categories(html_dsl)
    categories = Category.where("user_id = #{session[:user_id]} and category_id is null").order('name ASC')
    category_html = create_category_table(categories)
    html_dsl.inject(category_html)
  end

end
