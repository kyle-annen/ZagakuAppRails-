class CreateTopics < ActiveRecord::Migration[5.1]
  def change
    create_table :topics do |t|
      t.integer :category_id
      t.string :name
      t.string :path, uniqueness: true
      t.string :sha
      t.integer :size
      t.string :url
      t.string :html_url
      t.string :git_url
      t.string :download_url
      t.string :github_type
      t.timestamps
    end
  end
end
