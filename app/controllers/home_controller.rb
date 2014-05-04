class HomeController < ApplicationController
  def test
    @page = MyPage.new()
    @page.content = 'Enter note here'
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

