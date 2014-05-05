class TaskCategory < ActiveRecord::Base
#  attr_accessible :category_id, :note_id

# table references:
  belongs_to :task                                  # FK task_id => task.id
  belongs_to :category                              # FK category_id => category.id

  def initialize(attributes = {})
    super     # initialize active record.

    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
end
