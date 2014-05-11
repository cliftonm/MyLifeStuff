require 'clifton_lib/xml/xml_document'
require 'clifton_lib/xml/xml_text_writer'
include CliftonXml

# TODO: :one_column_per_row is obsolete
# TODO: :show_checkboxes is obsolete

module ApplicationHelper
  def show_field_error(model, field)
    s=''

    unless model.errors[field].empty?
      s = "<div id='error_message'>#{model.errors[field][0]}</div>"
    end

    s.html_safe
  end

  # Return HTML to represent the following record collection as a table.
  # Parameters:
  # table: The instance (usually a model) containing the table data
  # table_name: The name of the table, used to create the qualified row id's for the optional associated checkboxes:
  #    #{table_name}[record_#{row[:id]}]
  # columns: Array of column names to display
  # format: Array describing how a record's fields map to columns and rows.
  #    For example, a 5 field table displaying one record per line would have a format:
  #        [5]
  #    A table with 3 fields on one row and 2 fields on the second row:
  #        [3, 2]
  #    A table with one field per row, where there are 5 fields
  #        [1, 1, 1, 1, 1]
  # options: Various options that can be specified
  #    :id - the table element ID
  #    :class - the table classes, as a single string, for example: "class1 class2 class3"
  #    :no_header - do not create a table header section
  #    :show_checkbox_for_row - put a checkbox as the first column of the first row
  #    :auto_indent - for subsequent rows, auto-indent.  Applies only when :show_checkbox_for_row is true.
  #    :header_as_first_column - headers for all columns on the row go into the first column
  # &block: yield to caller at each row for creating sub-tables
  def create_table_view(table, table_name, columns, format, options = {}, &block)
    xdoc = XmlDocument.new()
    table_node = xdoc.create_element('table')
    append_attribute(table_node, options, :id)
    append_attribute(table_node, options, :class)
    xdoc.append_child(table_node)
    create_table_header(table_node, columns, format, options)
    create_table_content(table_node, table, table_name, columns, format, options, &block)
    get_html(xdoc).html_safe
  end

  # create just the headers for the table inside a <thead> section.
  def create_table_header(table_node, columns, format, options = {})
    unless options[:no_header]
      table_head_node = create_element(table_node, 'thead')
      col_idx = 0

      format.each_with_index do |cols_per_row, idx|
        table_row_node = create_element(table_head_node, 'tr')

        # If first index and we want to show checkboxes, then create a placeholder header column
        if (idx == 0 || options[:auto_indent]) && options[:show_checkbox_for_row]
          create_element(table_row_node, 'th')
        end

        # For the # of columns that we are going to display in this row:
        (1..cols_per_row).each do
          # Create the header
          column = columns[col_idx]
          table_heading_node = create_element(table_row_node, 'th')
          table_heading_node.inner_text = column.gsub('_', ' ').titleize
          # titleize is a Rails function.  For straight Ruby:
          # "kirk douglas".split(" ").map(&:capitalize).join(" ")
          col_idx += 1
        end
      end
    end

    nil
  end

  # Create the table body content.  No attention is paid to paging, etc.
  def create_table_content(table_node, table, table_name, columns, format, options)
    table_body_node = create_element(table_node, "tbody")

    table.each_with_index do |row, row_idx|
      col_idx = 0

      format.each_with_index do |cols_per_row, idx|
        table_row_node = create_element(table_body_node, 'tr')

        if idx == 0 && options[:show_checkbox_for_row]
          table_data_node = create_element(table_row_node, 'td')
          input_node = create_element(table_data_node, 'input')
          create_attribute(input_node, 'type', 'checkbox')
          create_attribute(input_node, 'name', record_name(table_name, row, row_idx))
        elsif idx > 0 && options[:show_checkbox_for_row] && options[:auto_indent]
          # create an empty column for subsequent rows to indent the data.
          create_element(table_row_node, 'td')
        end

        if options[:header_as_first_column]
          hdr_col = create_element(table_row_node, 'td')
          # The first column joins all the header names into a comma-separated list for the columns that go on this row.
          hdr_col.inner_text = columns[col_idx..col_idx+cols_per_row-1].join(', ')+':'
        end

        (1..cols_per_row).each do
          column = columns[col_idx]
          col_idx += 1
          table_data_node = create_element(table_row_node, 'td')
          text = row[column].to_s

          # Replace text with a custom specified renderer.
          if options[:custom_text_renderers]
            renderers = options[:custom_text_renderers]
            if renderers[column.to_sym]
              text = renderers[column.to_sym].call(text)
            end
          end

          table_data_node.inner_text = text
        end

        # Allow caller to specify additional HTML in the <tr>, for example to allow nesting of tables.
        if block_given?
          yield(row, table_row_node)
        end
      end
    end
=begin
      if options[:one_column_per_row]
        # first row is just a checkbox.
        # TODO: Caller should be able to label this checkbox perhaps.
        if options[:show_checkbox_for_row]
          table_row_node = create_element(table_body_node, 'tr')

          # first row, add a class allowing us to delineate records by some styling
          table_row_node.append_attribute(xdoc.create_attribute('class', 'next-record'))

          table_data_node = xdoc.create_element('td')
          input_node = xdoc.create_element('input')
          input_node.append_attribute(xdoc.create_attribute('type', 'checkbox'))
          input_node.append_attribute(xdoc.create_attribute('name', "#{table_name}[record_#{row[:id]}]"))
          table_data_node.append_child(input_node)
          table_row_node.append_child(table_data_node)
        end

        # next, each column is a separate row
        columns.each_with_index do |column, idx|
          table_row_node = xdoc.create_element('tr')
          table_body_node.append_child(table_row_node)

          if idx == 0 && !options[:show_checkbox_for_row]
            # first row, add a class allowing us to delineate records by some styling
            table_row_node.append_attribute(xdoc.create_attribute('class', 'next-record'))
          end

          # TODO : This is all hardcoded for notes right now
          # See here: http://jsfiddle.net/NVx4S/21/
          # The idea is to show/hide the note itself when the user clicks on the subject line.
          if idx==0
            # the first column is the field name
            table_data_node = xdoc.create_element('td')
            table_data_node.append_attribute(xdoc.create_attribute('class', 'clickme'))

            table_data_node.inner_text = column.gsub('_', ' ').titleize + ':'
            table_row_node.append_child(table_data_node)

            # the second column is the data
            table_data_node = xdoc.create_element('td')
            table_data_node.append_attribute(xdoc.create_attribute('class', 'clickme'))

            text = row[column].to_s

            # Replace text with a custom specified renderer.
            if options[:custom_text_renderers]
              renderers = options[:custom_text_renderers]
              if renderers[column.to_sym]
                text = renderers[column.to_sym].call(text)
              end
            end

            table_data_node.inner_text = text
            table_row_node.append_child(table_data_node)
          else
            # second row
            # just display the data (the note)
            table_row_node.append_attribute(xdoc.create_attribute('class', 'hideme'))
            table_data_node = xdoc.create_element('td')
            table_data_node.append_attribute(xdoc.create_attribute('colspan', '2'))
            table_row_node.append_child(table_data_node)
            div = xdoc.create_element('div')
            table_data_node.append_child(div)

            text = row[column].to_s

            # Replace text with a custom specified renderer.
            if options[:custom_text_renderers]
              renderers = options[:custom_text_renderers]
              if renderers[column.to_sym]
                text = renderers[column.to_sym].call(text)
              end
            end

            div.inner_text = text
=end
=begin
            # the second column is the data
            table_data_node = xdoc.create_element('td')
            table_data_node.append_attribute(xdoc.create_attribute('class', 'clickme'))

            text = row[column].to_s

            # Replace text with a custom specified renderer.
            if options[:custom_text_renderers]
              renderers = options[:custom_text_renderers]
              if renderers[column.to_sym]
                text = renderers[column.to_sym].call(text)
              end
            end

            table_data_node.inner_text = text
            table_row_node.append_child(table_data_node)
=end
=begin
          end
        end
      else
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
    end
=end
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
    category_html = create_table_view(categories, 'category_list', ["name"], [1], {show_checkbox_for_row: true}.merge(options)) { |category, node|
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

  # TODO: Replace with a real tree-view, rather than one generated from nested tables.
  # TODO: Duplicate code from creating category table.
  def create_task_table(tasks, options={})
    task_html = create_table_view(tasks, 'task_list', ["name"], {show_checkboxes: true}.merge(options)) { |task, node|
      # Process child tasks of the parent that has been passed in.
      child_tasks = Task.where("task_id = #{task.id}").order('name ASC')

      if child_tasks.count > 0
        # Use our current XmlDocument and node rather than starting with a new instance.
        # Allows us to easily continue adding nodes to an existing XmlDocument structure.
        gen = HtmlGenerator.new() {@xdoc = node.xml_document; @current_node = node}
        # Indent the child table by 10px.
        gen.div(nil, nil, 'margin-left:10px')
        child_html = create_task_table(child_tasks, {no_header: true})
        gen.inject(child_html)
        gen.div_end()

        # If you want to add the child table directly, without being wrapped in a div
        # or using the HtmlGenerator, here's a way you can do it:
        #        element = node.xml_document.create_xml_fragment(child_html)
        #        node.append_child(element)
      end
    }

    task_html
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

  # Creates the javascript to populate the edit boxes with the fields in the selected row.
  # Requires the model name and the field list.
  # The edit boxes are expected to have an ID of the form "[model]_[fieldname]"
  # TODO: Need to check the selected categories as well.
  def create_row_click_javascript(model, field_list, col_start)
=begin
  javascript = "<script type='text/javascript'>\r\n//<![CDATA[\r\n"
  javascript << "$('tr').each(function() {\r\n"
  javascript << "$(this).click(function() {"

  n = col_start
  field_list.each do |field|
    javascript << "var data = $(this).children(':nth-child(#{n})').text();"
    javascript << "$('##{model}_#{field}').val(data.trim());"
    n += 1
  end

  javascript << "});"
  javascript << "});"
  javascript << "//]]>\r\n</script>\r\n"
=end
  javascript = "<script type='text/javascript'>\r\n//<![CDATA[\r\n"
  javascript << "//]]>\r\n</script>\r\n"
  end

  # TODO: Consider using the function in the html_generator and html_dsl to create optional attributes.
  # Append an attribute of the specified symbol if it exists in the options list, with an optional
  # attribute name override for the symbol.
  def append_attribute(node, options, attr_sym, override_attr_name = nil)
    # Use the provided override attribute name if it exists, otherwise use the symbol
    attr_name = override_attr_name ? override_attr_name : attr_sym.to_s

    if options[attr_sym]
      node.append_attribute(node.xml_document.create_attribute(attr_name, options[attr_sym]))
    end
  end

  # If the record has an ID field, then we use that for the name checkbox record field,
  # otherwise we use the row count index.
  def record_name(table_name, row, row_idx)
    if row.respond_to?(:id)
      "#{table_name}[record_#{row[:id]}]"
    else
      "#{table_name}[record_#{row_idx}]"
    end
  end

  # TODO: Move these into clifton_lib as helper functions?

  # Create a child element of the given name for the specified node.
  # Return the child.
  def create_element(node, element_name)
    child = node.xml_document.create_element(element_name)
    node.append_child(child)

    child
  end

  # Create an attribute on the given node with the specified name and value.
  def create_attribute(node, attr_name, attr_val)
    node.append_attribute(node.xml_document.create_attribute(attr_name, attr_val))
  end

end
