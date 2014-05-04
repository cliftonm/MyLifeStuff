class NoteCategory < ActiveRecord::Base

# table references:
  belongs_to :note                                  # FK note_id => note.id
  belongs_to :category                              # FK category_id => category.id

  def initialize(attributes = {})
    super     # initialize active record.

    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
end
