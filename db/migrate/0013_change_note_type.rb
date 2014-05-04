class ChangeNoteType < ActiveRecord::Migration
  def self.up
    change_table :notes do |t|
      t.change :note, :text
    end
  end

  def self.down
  end
end
