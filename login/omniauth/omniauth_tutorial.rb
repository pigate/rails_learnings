#assumes you have installed devise. If not,
  #in Gemfile
  gem 'devise'
  #install devise
  $rails g devise:install
  #move over the devise views so that you can edit
  $rails g devise User
  $rails g devise:views #FIXME(??? check me)  
  #and see /devise for more information 

#go get id's and secrets from facebook, twitter, google+, whatever
        #save them 

#NOTE:
####

####

####

####
#NOTE: OMNIAUTH tutorial starts here....
0. initial setup:
#in Gemfile
gem 'twitter', '~> 5.3.1'
gem 'omniauth-twitter', '~> 1.0.1'
gem 'omniauth-facebook'
gem "omniauth-google-oauth2"
gem 'devise'

$bundle install

#To set up facebook,
#FOR TESTING ON LOCALHOST:
app_domain: #leave (BLANK)
Try to find a place to add a website url.
We had to '+ add platform' for that
Website Url: http://localhost:3000 #yay! it works for us!

We just have to switch it when we go into production mode.
#to set up omniauth and devise for google, I followed:
#src: http://blogs.burnsidedigital.com/2013/03/rails-3-devise-omniauth-and-google/
1. Create provider profiles and add your keys (place keys directly in file or set as environment variables (look up for windows, mac os. instructions for unix is at top of page)
#config/initializers/devise.rb
 config.omniauth :google_oauth2, '1063377016579-hs2v7pd59cenb3ir3jeppvnfmu230hme.apps.googleusercontent.com', '1TVsMxCy_cJIIG-Y9OuE0TIP'
 config.omniauth :facebook, ENV['FACEBOOK_ID'], ENV['FACEBOOK_SECRET']
end

2. Set up Route and Callback Controller
literally create:
  omniauth_callbacks_controller.rb
#app/controlers/omniauth_callbacks_controller.rb
class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    user = User.from_omniauth(request.env["omniauth.auth"])
      if user.persisted?
        flash.notice = "Signed in Through Google!"
        sign_in_and_redirect user
      else
        session["devise.user_attributes"] = user.attributes
       flash.notice = "You are almost Done! Please provide a password to finish setting up your account"
       redirect_to new_user_registration_url
    end
  end

  # .... one for every method like twitter, facebook... etc
end

#NOTE: 
  #You can make it less repitive with some sort of substitution. 
  #I'll find in stack overflow later

#app/models/user.rb
Make User able to use omniauth by adding ':omniauthable' to devise list
  devise_for :users, controllers: { omniauth_callbacks: "omniauth_callbacks" }

#NOW, set up route

#config/routes.rb

3. If haven't already yet, create user or add the member variables, uid, provider, username, email
  #if haven't created user yet:
  rails g devise User
  #else, add pertinent missing stuff to user
  rails g migration add_important_stuff_to_user
  #db/migrate/......add_important_stuff_to_user
      def change
        add_column :users, :uid, :string
        add_column :users, :provider, :string
        add_column :users, :username, :string
        #add_column :users, :email, :string #devise already adds these for you
        #add_index :users, :email
      end

4. AND make sure your app can find user. 
       I personally like being able to differentiate users by their email.
         That way, if they login with various providers but with same email,
         We can figure out whether it is them or not.
  #app/models/user.rb
  #method to instantiate user after being signed in with omniauth on 3rd party server
  def self.from_omniauth(auth)
    if user = User.find_by_email(auth.info.email)
      user.provider = auth.provider
      user.uid = auth.uid
      user
    else
      where(auth.slice(:provider, :uid)).first_or_create do |user|
        user.provider = auth.provider
        user.uid = auth.uid
        user.username = auth.info.name
        user.email = auth.info.email
        #user.avatar = auth.info.image
      end
    end
  end


Further notes:
From step 2, you can see that when user is found already in our database (they signed up and registered with us before), they are sent through somewhere.

Else, if this is their 'first time' here, they are sent to the new_user_registration page.

You can change what this page shows them. Ask me for more details.

