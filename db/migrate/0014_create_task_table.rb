class CreateTaskTable < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
      t.references :user
      t.references :task
      t.column :name, :string
    end

    # setup many-to-many table
    create_table :task_categories do |t|
      t.belongs_to :task        # FK to note.id
      t.belongs_to :category    # FK to category.id
    end
  end

  def self.down
    drop_table :task_categories
    drop_table :tasks
  end
end
