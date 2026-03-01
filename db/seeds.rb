# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

if User.none?
  User.create!(
    email: 'admin@example.com',
    name: 'admin',
    admin: true,
    password: 'adminadmin',
    password_confirmation: 'adminadmin',
    confirmed_at: Time.zone.now
  )
end
