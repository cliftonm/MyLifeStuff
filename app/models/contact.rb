class Contact < ActiveRecord::Base
  attr_accessible :user_id, :first_name, :last_name, :home_phone, :cell_phone, :work_phone, :email, :website, :address

  # table references:
  has_many :contact_categories, dependent: :destroy      # contact_category.contact_id is FK to contact.id
  has_many :categories, through: :contact_categories     # traverse m:m table to get to all the categories.
  belongs_to :user                                       # FK user_id => user.id

  def initialize(attributes = {})
    super     # initialize active record.

    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
end
