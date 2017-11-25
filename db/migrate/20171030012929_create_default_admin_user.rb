class CreateDefaultAdminUser < ActiveRecord::Migration[4.2]
  def up
    User.create!(email: "admin@example.com", name: "admin", admin: true,
      password: "adminadmin", password_confirmation: "adminadmin", confirmed_at: Time.now)
  end

  def down
  end
end
