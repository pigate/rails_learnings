#src: http://railscasts.com/episodes/278-search-with-sunspot?view=asciicast
#src: https://github.com/sunspot/sunspot
Adding search capability to rails project
#NOTE: to see my example, search for section #my_example
gem 'sunspot_rails'
gem 'sunspot_solr'
bundle install
rails generate sunspot_rails:install
bundle exec rake sunspot:solr:start # or sunspot:solr:run to start in foreground

#Set up your objects
class Post < ActiveRecord::Base
  searchable do
    text :title, :body #tells sunspot to index the title and body's full text
    text :comments do
      comments.map { |comment| comment.body } #just want the comment's body
    end

    boolean :featured #anything not text will be used for scoping
    integer :blog_id
    integer :author_id
    integer :category_ids, :multiple => true
    double  :average_rating
    time    :published_at
    time    :expired_at

    string  :sort_title do
      title.downcase.gsub(/^(an?|the)/, '')
    end
  end
end

Sunspot automatically indexes any new records but not existing ones. We can tell Sunspot to reindex the existing records by running

$ rake sunspot:reindex

#All posts are now in the solr database and can be search. 
#We can add a search field at top of the index page for Post
#app/views/posts/index.html.erb
<% title "Posts" %>

<%= form_tag posts_path, :method => :get do %>
    <%= text_field_tag :search, params[:search] %>
    <%= submit_tag "Search", :name => nil %>
<% end %>
<!-- rest of view omitted -->
  #NOTE: the form uses GET method so any search params can just be added to the query string
  #NOTE: must modify controller so that it can fetch posts using the 'search' param

#app/controllers/posts_controller.rb
def index
  @search = Post.search do
    fulltext params[:search]
  end
  @posts = @search.results
end

#Search for objects
Post.search do
  fulltext 'best pizza'

  with :blog_id, 1
  with(:published_at).less_than Time.now
  order_by :published_at, :desc
  paginate :page => 2, :per_page => 15
  facet :category_ids, :author_id
end

# All posts with a `text` field (:title, :body, or :comments) containing 'pizza'
Post.search { fulltext 'pizza' }

# Posts with pizza, scored higher if pizza appears in the title
Post.search do
  fulltext 'pizza' do
    boost_fields :title => 2.0
  end
end

# Posts with pizza, scored higher if featured
Post.search do
  fulltext 'pizza' do
    boost(2.0) { with(:featured, true) }
  end
end

# Posts with pizza *only* in the title
Post.search do
  fulltext 'pizza' do
    fields(:title)
  end
end

# Posts with pizza in the title (boosted) or in the body (not boosted)
Post.search do
  fulltext 'pizza' do
    fields(:body, :title => 2.0)
  end
end

#Search for phrase
# Posts with the exact phrase "great pizza"
Post.search do
  fulltext '"great pizza"'
end

# One word can appear between the words in the phrase, so "great big pizza"
# also matches, in addition to "great pizza"
Post.search do
  fulltext '"great pizza"' do
    query_phrase_slop 1
  end
end

Phrase boosts add boost to terms that appear in close proximity; the terms do not have to appear in a phrase, but if they do, the document will score more highly.

# Matches documents with great and pizza, and scores documents more
# highly if the terms appear in a phrase in the title field
Post.search do
  fulltext 'great pizza' do
    phrase_fields :title => 2.0
  end
end

# Matches documents with great and pizza, and scores documents more
# highly if the terms appear in a phrase (or with one word between them)
# in the title field
Post.search do
  fulltext 'great pizza' do
    phrase_fields :title => 2.0
    phrase_slop   1
  end
end

#my_example
#after installing sunspot, et. al
# [1] set up model to be searchable. Can choose which fields are used to index, which fields to use as scope
class Movie < ActiveRecord::Base
  searchable do
    text :name
    text :spoiler do
      spoiler.try(:synopsis) #in case spoiler == nil. movie only has one spoiler
    end
    text :ratings do #movie has multiple ratings
       ratings.map { |rating| rating.review }
    end
    integer :genre_ids, :multiple => true
  end
end

# [2] set up the pertinent controller to respond to search query
class StaticPagesController < ApplicationController
  def front
    @movies = Movie.take(5)
  end
  def search_page
    @search = nil
    @movies = nil
    @actors = nil
    @directors = nil
    @genres = nil
    if (params[:search_for] == "movies" || true )
      @search = Movie.search do
        fulltext params[:search]
      end
      @movies = @search.results #Movie.all
      store_location
    #else actors, dire, genres, etc
    end
  end
end

# [3] Optional, set up route
  match 'search' => "static_pages#search_page", via: :get

# [4] Set up search form. You can put this in any view you like
# it will perform search query, and redirect back to the path in form_tag

  <%= form_tag search_path, :method => :get do %>
    <%= text_field_tag :search, params[:search] %>
  <%= submit_tag "Search", :name => nil %>

