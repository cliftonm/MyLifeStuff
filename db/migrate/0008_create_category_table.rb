class CreateCategoryTable < ActiveRecord::Migration
  def self.up
    # Categories belong to users.
    # Categories also have an optional parent.
    create_table :categories do |t|
      t.references :user
      t.references :category
      t.column :name, :string
    end
  end

  def self.down
    drop_table :categories
  end
end
