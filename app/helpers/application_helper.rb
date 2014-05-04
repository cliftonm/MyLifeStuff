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
  def create_table_view(table, table_name, columns, options = {}, &block)
    xdoc = XmlDocument.new()
    table_node = xdoc.create_element('table')
    xdoc.append_child(table_node)

    # We may not want to display the header, for example, nested tables in a "tree view" kind of display.
    unless options[:no_header]
      create_table_header(xdoc, table_node, columns, options)
    end

    create_table_content(xdoc, table_node, table, table_name, columns, options, &block)

    get_html(xdoc).html_safe
  end

  # create just the headers for the table inside a <thead> section.
  def create_table_header(xdoc, table_node, columns, options = {})
    table_head_node = xdoc.create_element('thead')
    table_node.append_child(table_head_node)
    table_row_node = xdoc.create_element('tr')
    table_head_node.append_child(table_row_node)

    # create an empty column if showing a checkbox for the row.
    if options[:show_checkbox_for_row]
      table_heading_node = xdoc.create_element('th')
      table_row_node.append_child(table_heading_node)
    end

    columns.each do |column|
      table_heading_node = xdoc.create_element('th')
      table_heading_node.inner_text = column.gsub('_', ' ').capitalize
      table_row_node.append_child(table_heading_node)
    end

    nil
  end

  # Create the table body content.  No attention is paid to paging, etc.
  def create_table_content(xdoc, table_node, table, table_name, columns, options)
    table_body_node = xdoc.create_element("tbody")
    table_node.append_child(table_body_node)

    table.each do |row|
      table_row_node = xdoc.create_element('tr')
      table_body_node.append_child(table_row_node)

      # show checkbox in the first column separate from all other data columns
      if options[:show_checkbox_for_row]
        table_data_node = xdoc.create_element('td')
        input_node = xdoc.create_element('input')
        input_node.append_attribute(xdoc.create_attribute('type', 'checkbox'))
        input_node.append_attribute(xdoc.create_attribute('name', "#{table_name}[record_#{row[:id]}]"))
        table_data_node.append_child(input_node)
        table_row_node.append_child(table_data_node)
      end

      columns.each_with_index do |column, idx|
        table_data_node = xdoc.create_element('td')

        text = row[column].to_s

        # Replace text with a custom specified renderer.
        if options[:custom_text_renderers]
          renderers = options[:custom_text_renderers]
          if renderers[column.to_sym]
            text = renderers[column.to_sym].call(text)
          end
        end

        # show checkboxes for each column and row.
        if options[:show_checkboxes]
          input_node = xdoc.create_element('input')
          input_node.append_attribute(xdoc.create_attribute('type', 'checkbox'))
          input_node.append_attribute(xdoc.create_attribute('name', "#{table_name}[record_#{row[:id]}]"))
          input_node.inner_text = text
          table_data_node.append_child(input_node)
        # show checkboxes for only the first column.
        elsif options[:show_checkbox_first_column] && idx == 0
          input_node = xdoc.create_element('input')
          input_node.append_attribute(xdoc.create_attribute('type', 'checkbox'))
          input_node.append_attribute(xdoc.create_attribute('name', "#{table_name}[record_#{row[:id]}]"))
          input_node.inner_text = text
          table_data_node.append_child(input_node)
        else
          table_data_node.inner_text = text
        end

        table_row_node.append_child(table_data_node)

        # Allow caller to specify additional HTML in the <td>, for example to allow nesting of tables.
        if block_given?
          yield(row, table_data_node)
        end
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

  # TODO: Replace with a real tree-view, rather than one generated from nested tables.
  def create_category_table(categories, options={})
    category_html = create_table_view(categories, 'category_list', ["name"], {show_checkboxes: true}.merge(options)) { |category, node|
      # Process child categories of the parent that has been passed in.
      child_categories = Category.where("category_id = #{category.id}").order('name ASC')

      if child_categories.count > 0
        # Use our current XmlDocument and node rather than starting with a new instance.
        # Allows us to easily continue adding nodes to an existing XmlDocument structure.
        gen = HtmlGenerator.new() {@xdoc = node.xml_document; @current_node = node}
        # Indent the child table by 10px.
        gen.div(nil, nil, 'margin-left:10px')
        child_html = create_category_table(child_categories, {no_header: true})
        gen.inject(child_html)
        gen.div_end()

        # If you want to add the child table directly, without being wrapped in a div
        # or using the HtmlGenerator, here's a way you can do it:
        #        element = node.xml_document.create_xml_fragment(child_html)
        #        node.append_child(element)
      end
    }

    category_html
  end

  # parse the "[recordNname]_[n]" string and return only [n]
  def get_record_id(record)
    record[0].partition('_').last.to_i
  end

  def get_checked(val)
    if val
      true
    else
      false
    end
  end

end
