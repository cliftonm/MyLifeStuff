class CreateAccountsTable < ActiveRecord::Migration
  def self.up
    create_table :accounts do |t|
      t.references :user
      t.column :name, :string
      t.column :url, :string
      t.column :username, :string
      t.column :password, :string
      t.column :acct_number, :string
      t.column :due_on, :integer
      t.column :notes, :string
    end

    # setup many-to-many table
    create_table :account_categories do |t|
      t.belongs_to :account     # FK to account.id
      t.belongs_to :category    # FK to category.id
    end
end

  def self.down
    drop_table :account_categories
    drop_table :accounts
  end
end
