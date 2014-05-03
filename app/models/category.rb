class Category < ActiveRecord::Base
  attr_accessible :category_id, :name, :user_id
  validates_presence_of :name

  def initialize(attributes = {})
    super     # initialize active record.

    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
end
