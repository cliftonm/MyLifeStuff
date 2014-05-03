class Category < ActiveRecord::Base
  attr_accessible :category_id, :name, :user_id
  validates_presence_of :name

  has_many :categories, dependent: :destroy         # category.category_id is FK to category.id
  belongs_to :user                                  # FK user_id => user.id
  belongs_to :category                              # FK category_id => category.id

  def initialize(attributes = {})
    super     # initialize active record.

    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
end
