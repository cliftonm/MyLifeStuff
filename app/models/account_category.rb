class AccountCategory < ActiveRecord::Base
#  attr_accessible :category_id, :account_id

  # table references:
  belongs_to :account                               # FK account_id => account.id
  belongs_to :category                              # FK category_id => category.id

  def initialize(attributes = {})
    super     # initialize active record.

    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
end
