class SeparateFirstLastName < ActiveRecord::Migration
  def self.up
    remove_column :contacts, :name
    add_column :contacts, :first_name, :string
    add_column :contacts, :last_name, :string
  end

  def self.down
  end
end
