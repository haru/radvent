# frozen_string_literal: true

# Represents a user in the system.
#
# Users can create events, publish articles, like items, and comment.
# Uses Devise for authentication.
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :rememberable, :trackable, :validatable,
         :timeoutable, :recoverable
  validates :name, presence: true

  # Checks if the user is an administrator.
  #
  # @return [Boolean] true if the user has admin privileges
  def admin?
    admin == true
  end
end
