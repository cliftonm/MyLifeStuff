class Account < ActiveRecord::Base
  attr_accessible :user_id, :name, :url, :username, :password, :acct_number, :due_on, :notes

  # table references:
  has_many :account_categories, dependent: :destroy      # account_category.account_id is FK to account.id
  has_many :categories, through: :account_categories     # traverse m:m table to get to all the categories.

  def initialize(attributes = {})
    super     # initialize active record.

    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
end
