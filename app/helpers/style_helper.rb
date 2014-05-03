require 'style'
include Airity

module StyleHelper
  class AppStyles
    attr_reader :css
    attr_reader :input_label
    attr_reader :inline_div
    attr_reader :clear_both

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

      styles =
          [
              @input_label.get_css(),
              @inline_div.get_css(),
              @clear_both.get_css(),
          ]

      @css = "\r\n<style type='text/css'>\r\n" + styles.join("\r\n") + "</style>\r\n"
    end
  end
end
