class Note < ActiveRecord::Base
  attr_accessible :user_id, :subject, :note

  # table references:
  has_many :note_categories, dependent: :destroy      # note_categories.note_id is FK to note.id
  has_many :categories, through: :note_categories     # traverse m:m table to get to all the categories.
  belongs_to :user                                       # FK user_id => user.id

  def initialize(attributes = {})
    super     # initialize active record.

    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
end
