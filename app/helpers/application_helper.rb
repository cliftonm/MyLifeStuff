require 'clifton_lib/xml/xml_document'
require 'clifton_lib/xml/xml_text_writer'
include CliftonXml

module ApplicationHelper
  def show_field_error(model, field)
    s=''

    unless model.errors[field].empty?
      s = "<div id='error_message'>#{model.errors[field][0]}</div>"
    end

    s.html_safe
  end

  # Return HTML to represent the following record collection as a table.
  def create_table_view(table, columns, options = {})
    xdoc = XmlDocument.new()
    table_node = xdoc.create_element('table')
    xdoc.append_child(table_node)
    create_table_header(xdoc, table_node, columns, options)
    create_table_content(xdoc, table_node, table, columns, options)

    get_html(xdoc).html_safe
  end

  # create just the headers for the table inside a <thead> section.
  def create_table_header(xdoc, table_node, columns, options = {})
    table_head_node = xdoc.create_element('thead')
    table_node.append_child(table_head_node)
    table_row_node = xdoc.create_element('tr')
    table_head_node.append_child(table_row_node)

    columns.each do |column|
      table_heading_node = xdoc.create_element('th')
      table_heading_node.inner_text = column.capitalize
      table_row_node.append_child(table_heading_node)
    end

    nil
  end

  # Create the table body content.  No attention is paid to paging, etc.
  def create_table_content(xdoc, table_node, table, columns, options = {})
    table_body_node = xdoc.create_element("tbody")
    table_node.append_child(table_body_node)

    table.each do |row|
      table_row_node = xdoc.create_element('tr')
      table_body_node.append_child(table_row_node)

      columns.each do |column|
        table_data_node = xdoc.create_element('td')

        if options[:show_checkboxes]
          input_node = xdoc.create_element('input')
          input_node.append_attribute(xdoc.create_attribute('type', 'checkbox'))
          input_node.append_attribute(xdoc.create_attribute('name', "table[record_#{row[:id]}]"))
          input_node.inner_text = row[column]
          table_data_node.append_child(input_node)
        else
          table_data_node.inner_text = row[column]
        end

        table_row_node.append_child(table_data_node)
      end
    end

    nil
  end

  # Get the HTML for the XmlDocument.
  def get_html(xdoc)
    tw = XmlTextWriter.new()                # create a text writer
    tw.formatting = :indented
    tw.allow_self_closing_tags = false      # HTML5 compliance
    xdoc.save(tw)                           # generate the HTML

    tw.output
  end
end
