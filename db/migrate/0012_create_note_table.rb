class CreateNoteTable < ActiveRecord::Migration
  def self.up
    create_table :notes do |t|
      t.references :user
      t.column :subject, :string
      t.column :note, :string
      t.timestamps
    end

    # setup many-to-many table
    create_table :note_categories do |t|
      t.belongs_to :note        # FK to note.id
      t.belongs_to :category    # FK to category.id
    end
  end

  def self.down
    drop_table :note_categories
    drop_table :notes
  end
end
