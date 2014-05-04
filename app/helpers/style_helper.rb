require 'style'
include Airity

module StyleHelper
  class AppStyles
    attr_reader :css
    attr_reader :input_label
    attr_reader :inline_div
    attr_reader :clear_both
    attr_reader :scrollable_div300
    attr_reader :contact_table
    attr_reader :account_table
    attr_reader :div_fill

    def initialize()
      @input_label = Style.new {
        @style_name = 'input-label'
        @styles =
            {
                width: '100px',
                display: 'inline-block',
                text_align: 'right'
            }
      }

      @inline_div = Style.new {
        @style_name = 'inline-div'
        @styles =
            {
                float: 'left',
            }
      }

      @clear_both = Style.new {
        @style_name = 'clear-both'
        @styles =
            {
                clear: 'both'
            }
      }

      @scrollable_div300 = Style.new {
        @style_name = 'scrollable-div300'
        @styles =
            {
                height: '300px',
                overflow: 'auto',
                direction: 'rtl'
            }
      }

      @div_fill = Style.new {
        @style_name = 'div-fill'
        @styles =
            {
                float: 'right'
            }
      }

      # The outer div is rtl, putting the scrollbar on the left, so we need to specify the ltr for the table contents.
      @contact_table = Style.new {
        @style_name = 'contact-table'
        @styles =
            {
                direction: 'ltr',
                float: 'left'
            }
      }

      # The outer div is rtl, putting the scrollbar on the left, so we need to specify the ltr for the table contents.
      @account_table = Style.new {
        @style_name = 'account-table'
        @styles =
            {
                direction: 'ltr',
                float: 'left'
            }
      }

      styles =
          [
              @input_label.get_css(),
              @inline_div.get_css(),
              @clear_both.get_css(),
              @scrollable_div300.get_css(),
              @contact_table.get_css(),
              @account_table.get_css(),
              @div_fill.get_css(),
          ]

      @css = "\r\n<style type='text/css'>\r\n" + styles.join("\r\n") + "</style>\r\n"
    end
  end
end
