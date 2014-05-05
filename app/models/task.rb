class Task < ActiveRecord::Base
  attr_accessible :task_id, :name, :user_id
  validates_presence_of :name

  # table references:
  has_many :tasks, dependent: :destroy          # task.task_id is FK to task.id
  has_many :categories, through: :account_categories     # traverse m:m table to get to all the categories.
  belongs_to :user                              # FK user_id => user.id
  belongs_to :task                              # FK task_id => task.id

  def initialize(attributes = {})
    super     # initialize active record.

    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
end
