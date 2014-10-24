/10e you read likes_votes? 
#Well, make sure you read it before reading this file.
Assumptions:
#scaffold Movie (alias: voted_movie)
#scaffold User (alias: voter)
#model Vote (voter_id:string, voted_movie:string)

# necessary session params, esp. current_user (returns current user logged in)

#Premise: Movies are voted on. 
=begin
On Movie's show page, shows how many votes for movie.
If you are signed in, it will also display option to 'unvote', or 'vote', if you haven't.
When you click it, ideally, movie's # votes will change +1/-1.
IF you had clicked vote now/before, it will show the 'unvote' form.
Else, it will show 'vote' form.

Desire this to be done asynchronously, without having to refresh page.
Use AJAX !
=end
app/models/user.rb

class User < ActiveRecord::Base

  def voted_for?(movie)
    votes.find_by(voted_movie_id: movie.id)
  end

  def vote!(movie)
    votes.create!(voted_movie_id: movie.id)
  end
  
  def unvote!(movie)
   votes.find_by(voted_movie_id: movie.id).destroy
  end
end
#views/movies/show.html.erb
 <%= render 'vote_form' if signed_in? %>

############################################3
#views/movies/_vote_form.html.erb
<% if signed_in%>
  <div id="vote_form">
  <% if current_user.voted_for?(@movie) %>
    <%= render 'unvote' %>
  <% else %>
    <%= render 'vote' %>
  <% end %>
  </div>
<% end %>

#can do: @movie.voters.include?(current_user)


###########################################
#USES AJAX AJAX AJAX. see below. 

build calls VotesController.create
create will have to execute create.js.erb

#config/routes.rb
  resources :votes, only: [:create, :destroy]

#views/movies/_vote.html.erb
<%= form_for(@movie.votes.build(voter_id: current_user[:id]),
             remote: true) do |f| %>
  <div><%= f.hidden_field :voter_id %></div>
  <%= f.submit "Follow", class: "btn btn-large btn-primary" %>
<% end %>

##########################################
#views/movies/_unvote.html.erb

#calls VotesController.destroy
#destroy will have to execute destroy.js.erb
<%= form_for(@movie.votes.find_by(voter_id: @user.id),
             html: { method: :delete },
             remote: true) do |f| %>
  <%= f.submit "Unfollow", class: "btn btn-large" %>
<% end %>


#################################################3
#app/controllers/votes_controller.rb
class VotesController < ApplicationController
  before_action :signed_in_user

  def create
    @movie = User.find(params[:vote][:voted_movie_id])
    current_user.vote!(@movie)
    respond_to do |format|
      format.html { redirect_to @movie }
      format.js #when use ajax, calls on this
    end
  end

  def destroy
    @movie = Vote.find(params[:id]).voted_movie
    current_user.unvote!(@movie)
    respond_to do |format|
      format.html { redirect_to @movie }
      format.js
    end
  end
end

##################################################
#app/views/relationships/create.js.erb

$("#follow_form").html("<%= escape_javascript(render('users/unfollow')) %>")
$("#followers").html('<%= @user.followers.count %>')

####################################################

#app/views/relationships/destroy.js.erb

$("#follow_form").html("<%= escape_javascript(render('users/follow')) %>")
$("#followers").html('<%= @user.followers.count %>')

