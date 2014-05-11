require 'html_dsl'
require 'html_generator'

include ApplicationHelper
include Airity
include StyleHelper

class DemoData
  attr_accessor :field1, :field2, :field3, :field4, :field5

  def initialize(f1, f2, f3, f4, f5)
    @field1 = f1
    @field2 = f2
    @field3 = f3
    @field4 = f4
    @field5 = f5
  end

  def [](field_name)
    self.send(field_name.to_s)
    # "#{field_name}=" is the setter.
  end
end

class HomeController < ApplicationController
  def test
    @page = MyPage.new()
    @page.content = 'Enter note here'
  end

  def table_demo
    r1 = DemoData.new('r1f1', 'r1f2', 'r1f3', 'r1f4', 'r1f5')
    r2 = DemoData.new('r2f1', 'r2f2', 'r2f3', 'r2f4', 'r2f5')
    r3 = DemoData.new('r3f1', 'r3f2', 'r3f3', 'r3f4', 'r3f5')
    r4 = DemoData.new('r4f1', 'r4f2', 'r4f3', 'r4f4', 'r4f5')
    r5 = DemoData.new('r5f1', 'r5f2', 'r5f3', 'r5f4', 'r5f5')
    data = [r1, r2, r3, r4, r5]
    @child_data = [r1]

    html_dsl = HtmlDsl.new()

    # A simple table:
    html_dsl.div() do
      html_dsl.label('Simple table:')
      html_dsl.line_break()
      html = create_table_view(data, 'Demo', ['field1', 'field2', 'field3', 'field4', 'field5'], [5])
      html_dsl.inject(html)
    end

    html_dsl.line_break()

    # A simple table with no header:
    html_dsl.div() do
      html_dsl.label('Simple table with no header:')
      html_dsl.line_break()
      html = create_table_view(data, 'Demo', ['field1', 'field2', 'field3', 'field4', 'field5'], [5], {no_header: true})
      html_dsl.inject(html)
    end

    html_dsl.line_break()

    # A simple table with a leading checkbox column:
    html_dsl.div() do
      html_dsl.label('Simple table with checkboxes:')
      html_dsl.line_break()
      html = create_table_view(data, 'Demo', ['field1', 'field2', 'field3', 'field4', 'field5'], [5], {show_checkbox_for_row:true})
      html_dsl.inject(html)
    end

    html_dsl.line_break()

    # Table with three columns on the first row, then two columns on the second row, and checkboxes only on the first row
    html_dsl.div() do
      html_dsl.label('Two rows, three columns / two columns with checkbox on the first row:')
      html_dsl.line_break()
      html = create_table_view(data, 'Demo', ['field1', 'field2', 'field3', 'field4', 'field5'], [3, 2], {show_checkbox_for_row:true})
      html_dsl.inject(html)
    end

    html_dsl.line_break()

    # Table with three columns on the first row, then two columns on the second row, and checkboxes only on the first row, subsequent rows are indented
    html_dsl.div() do
      html_dsl.label('Two rows, three columns / two columns with checkbox on the first row, auto-indented:')
      html_dsl.line_break()
      html = create_table_view(data, 'Demo', ['field1', 'field2', 'field3', 'field4', 'field5'], [3, 2], {show_checkbox_for_row:true, auto_indent:true})
      html_dsl.inject(html)
    end

    html_dsl.line_break()

    # Table with four rows per record, first row has two columns, rest have one column, with column label as first column in table.
    html_dsl.div() do
      html_dsl.label('Table with four rows per record, first row has two columns, rest have one column, with column label as first column in table:')
      html_dsl.line_break()
      html = create_table_view(data, 'Demo', ['field1', 'field2', 'field3', 'field4', 'field5'], [2, 1, 1, 1], {header_as_first_column:true, no_header:true})
      html_dsl.inject(html)
    end

    html_dsl.line_break()

    # Table with four rows per record, first row has two columns, rest have one column, with column label as first column in table and checkbox in the first row, auto-indentation.
    html_dsl.div() do
      html_dsl.label('Table with four rows per record, first row has two columns, rest have one column, with column label as first column in table:')
      html_dsl.line_break()
      html = create_table_view(data, 'Demo', ['field1', 'field2', 'field3', 'field4', 'field5'], [2, 1, 1, 1], {header_as_first_column:true, no_header:true, show_checkbox_for_row:true, auto_indent:true})
      html_dsl.inject(html)
    end

    html_dsl.line_break()

    # Nested tables:
    html_dsl.div() do
      html_dsl.label('Nested table, one field per row, with inner rows of two columns:')
      html_dsl.line_break()
      options = {header_as_first_column:true, no_header:true, show_checkbox_for_row:true, auto_indent:true}
      html = create_table_view(data,
                               'Demo',
                               ['field1'],
                               [1],
                               options) do  |record, node|
        gen = HtmlGenerator.new() {@xdoc = node.xml_document; @current_node = node}
        gen.div(nil, nil, 'margin-left:10px')
        # Child data can of course be dependent on parent record passed into block.
        child_html = create_table_view(@child_data, 'Child', ['field2', 'field3'], [2], {no_header: true})  # can be recursive, etc...
        gen.inject(child_html)
        gen.div_end()
      end

      html_dsl.inject(html)
    end

    @html = get_html(html_dsl.html_gen.xdoc).html_safe
  end

  def my_pages

  end

  def my_pages_post
    redirect_to :test
  end
end


class MyPage
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :notes
  attr_accessor :content
  attr_accessor :info

  def persisted?
    false
  end

end

