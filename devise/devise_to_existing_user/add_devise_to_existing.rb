#Situation: suppose you have an existing rails app, with existing user model.
# you like your user model bc you get to access its views, especially index and show, which devise does not give you...

#src: https://github.com/plataformatec/devise/wiki/How-To:-Change-an-already-existing-table-to-add-devise-required-columns

# NOTE: ensure that you do not write 'devise_for :users' anywhere yet, ok?!
[1] setup devise
#gemfile
gem 'devise'

$bundle install
$rails g devise:install

[2] use devise on the User

$rails g devise User #yeah I just did it. just remove any columns in migration that may be duplicated

#partial src: https://github.com/plataformatec/devise/wiki/How-To:-Upgrade-to-Devise-2.0-migration-schema-style

#just run a migration, adding whatever you don't already have in user schema

#NOTE: If user schema has email, don't add another.
#NOTE: Don't add the timestamps either, and anything else that has duplicates

class AddDeviseColumnsToUser < ActiveRecord::Migration
  def change
    change_table :users do |t|
      #t.string :email
      t.string :encrypted_password, :null => false, :default => '', :limit => 128
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, :default => 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip
      t.string :password_salt

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable
     ## Lockable
      t.integer  :failed_attempts, :default => 0 # Only if lock strategy is :failed_attempts
      t.string   :unlock_token # Only if unlock strategy is :email or :both
      t.datetime :locked_at
     # Token authenticatable
      t.string :authentication_token

     ## Invitable
      t.string :invitation_token
    end
  end
end


$rake db:migrate
#rake routes to check if devise routes made it in
$ rake routes
                  Prefix Verb   URI Pattern                    Controller#Action
        new_user_session GET    /users/sign_in(.:format)       devise/sessions#new
            user_session POST   /users/sign_in(.:format)       devise/sessions#create
    destroy_user_session DELETE /users/sign_out(.:format)      devise/sessions#destroy
           user_password POST   /users/password(.:format)      devise/passwords#create
       new_user_password GET    /users/password/new(.:format)  devise/passwords#new
      edit_user_password GET    /users/password/edit(.:format) devise/passwords#edit
                         PATCH  /users/password(.:format)      devise/passwords#update
                         PUT    /users/password(.:format)      devise/passwords#update
cancel_user_registration GET    /users/cancel(.:format)        devise/registrations#cancel
       user_registration POST   /users(.:format)               devise/registrations#create
   new_user_registration GET    /users/sign_up(.:format)       devise/registrations#new
  edit_user_registration GET    /users/edit(.:format)          devise/registrations#edit
                         PATCH  /users(.:format)               devise/registrations#update
                         PUT    /users(.:format)               devise/registrations#update
                         DELETE /users(.:format)               devise/registrations#destroy
#my old stuff
                   users GET    /users(.:format)               users#index
                         POST   /users(.:format)               users#create
                new_user GET    /users/new(.:format)           users#new
               edit_user GET    /users/:id/edit(.:format)      users#edit
                    user GET    /users/:id(.:format)           users#show
                         PATCH  /users/:id(.:format)           users#update
                         PUT    /users/:id(.:format)           users#update
                         DELETE /users/:id(.:format)           users#destroy

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[3] Get rid of unnecessary controller methods/views. 
    leave the setup method in UsersController

#I want to use devise's methods for registering, sign in, etc.
#The only methods I only wanted to keep from original user is #index, #show

     #remove some views and controller methods that correspon to the unwanted, such as users#new, #edit, #update


#And restrict the routes so that users#edit, users#update, users#new don't show up again

#config/routes.rb
  resources :users, only: [:index, :show, :destroy]
  #NOTE: I kept users#destroy so that an admin can delete other users

$rake routes
                  Prefix Verb   URI Pattern                    Controller#Action
        new_user_session GET    /users/sign_in(.:format)       devise/sessions#new
            user_session POST   /users/sign_in(.:format)       devise/sessions#create
    destroy_user_session DELETE /users/sign_out(.:format)      devise/sessions#destroy
           user_password POST   /users/password(.:format)      devise/passwords#create
       new_user_password GET    /users/password/new(.:format)  devise/passwords#new
      edit_user_password GET    /users/password/edit(.:format) devise/passwords#edit
                         PATCH  /users/password(.:format)      devise/passwords#update
                         PUT    /users/password(.:format)      devise/passwords#update
cancel_user_registration GET    /users/cancel(.:format)        devise/registrations#cancel
       user_registration POST   /users(.:format)               devise/registrations#create
   new_user_registration GET    /users/sign_up(.:format)       devise/registrations#new
  edit_user_registration GET    /users/edit(.:format)          devise/registrations#edit
                         PATCH  /users(.:format)               devise/registrations#update
                         PUT    /users(.:format)               devise/registrations#update
                         DELETE /users(.:format)               devise/registrations#destroy
                   users GET    /users(.:format)               users#index
                    user GET    /users/:id(.:format)           users#show
                    user DELETE /users/:id                     users#delete

    #%%%%%%%%%%%%%%%
    # do you notice these lines? all say /users(.:format)
    #That means that to link to any of them, just use 'user_registration' as the resource, and pick which http method you want to define which action you want to take
    
       user_registration POST   /users(.:format)               devise/registrations#create
                         PATCH  /users(.:format)               devise/registrations#update
                         PUT    /users(.:format)               devise/registrations#update
                         DELETE /users(.:format)               devise/registrations#destroy
                   users GET    /users(.:format)               users/#index
  
     #%%%%%%%%%%%


#devise provides some default methods, very convenient:
current_user
if user_signed_in?
end

#NOTE: may need to change some links and some routes, esp. for sign_out


[4] Update some links on users#index, #show page

  edit_user_path ---> 
      <%= link_to 'Edit', edit_user_registration_path(current_user) %> 
      #just for you. the signed in user
  edit_user_path --> 
      <%= link_to 'Edit', edit_user_registration_path(user) %> 
         #when it is avaiable in for loop. only allow admin to access.
         #for more information on admin, see ./admin

  new_user_path --- >
       <%= link_to 'New User', new_user_registration_path %>

  DELETE yourself --> 
      <%= link_to 'Destroy', user_registration_path, :method => :delete, data: { confirm: 'Are you sure?' } %>   
     #but you can only edit/delete yourself with this link... any button you press will delete you.
     #since user_registration_path returns you.

   #WHY? Because devise treats users as a 'SINGULAR RESOURCE'.  
   #see '/routing/singular_resources' for more...
 
  sign out -->
  #Forcing /users/sign_out to work. 
  #Since /users/:id exists from earlier, 
  # /users/sign_out, which is a devise path,
  #   will look like it is trying to force 'id' = 'sign_out'. 
  #So we need to help it out by overmapping /users/sign_out

 #config/routes.rb
 devise_scope :user do
    get '/users/sign_out' => 'devise/sessions#destroy'
  end

 #views/layouts/application.html.erb           
<% if user_signed_in? %>
  yay!
  <%= link_to "Sign out", destroy_user_session_path, :method => :delete%>
<% end %>


[5] Overriding controllers
#so the original user controller methods you may want to keep some. 
#You may want to override the devise's controllers
#How to access Devise's controllers

#Devise uses internal controllers, which you can access and subclass in your own code. They are under the Devise module. For example, to extend the RegistrationsController:

class MembershipsController < Devise::RegistrationsController
  # ...
end

Then all you have to do is configure Devise''s routes to use your controller instead:

devise_for :members, :controllers => { :registrations => 'memberships' }

[6] Some authority stuff:
#app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :set_user, only: [:show, :destroy]
  before_action :correct_or_admin, only: [:destroy]
  private
    def correct_or_admin_user
      current_user.try(:admin?) || current_user == @user
    end
end
