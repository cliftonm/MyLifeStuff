require 'html_dsl'
require 'html_generator'

include ApplicationHelper
include Airity
include StyleHelper

class PicsController < ApplicationController
  def photo_album
    @is_album = true
    files = Dir.entries("./public/mompics").select {|f| f.ends_with?('.jpg')}
    html_dsl = HtmlDsl.new()

    file_index = 0

    html_dsl.table do
      while file_index < files.count
        html_dsl.table_row do
          (0..3).each do |n|
            html_dsl.table_data do
              if file_index < files.count
                html_dsl.image("/mompics/#{files[file_index]}", {width:"200", height:"200"})
                file_index += 1
              end
            end
          end
        end
      end
    end

    @album_html = get_html(html_dsl.html_gen.xdoc).html_safe
  end
end
