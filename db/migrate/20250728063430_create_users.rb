class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :external_id
      t.string :temp_session_token

      t.timestamps
    end
  end
end
