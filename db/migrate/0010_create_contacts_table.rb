class CreateContactsTable < ActiveRecord::Migration
  def self.up
    create_table :contacts do |t|
      t.references :user
      t.column :name, :string
      t.column :home_phone, :string
      t.column :cell_phone, :string
      t.column :work_phone, :string
      t.column :email, :string
      t.column :website, :string
      t.column :address, :string
    end
  end

  # setup many-to-many table
  create_table :contact_categories do |t|
    t.belongs_to :contact     # FK to contact.id
    t.belongs_to :category    # FK to category.id
  end

  def self.down
    drop_table :contact_categories
    drop_table :contacts
  end
end
