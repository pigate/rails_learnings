#app/models/user.rb

=begin
email:string
password:string
first_name:string
last_name:string
password_digest:string
remember_token:string  
=end

class User < ActiveRecord::Base
  #users.password_hash in DB is a :string
  include BCrypt

  before_save { self.email = email.downcase }
  validates :name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence:   true,
                    format:     { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, length: { minimum: 6 }

end

#app/controllers/users_controller.rb
#only safe to edit params go here.
  private
   def user_params
      params.require(:user).permit(:name, :email, :password,
                                   :password_confirmation)
    end

