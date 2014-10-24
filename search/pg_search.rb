#src: https://github.com/Casecommons/pg_search
#src: http://dev.mikamai.com/post/77171462056/easy-full-text-search-with-postgresql-and-rails

A free (esp. if you are using heroku) search method.
Has more functionality: can do 'fuzzy' search
  eg) 'cats' matchs 'catz', 'catsup', 'cats', 'cat'

#[1] prepare model for pg search

#models/movies.rb
class Movie < ActiveRecord::Base
  include PgSearch
end

#[2] Choose scope to search with
#Method a. multi-search 
  records of many diff classes can be mixed together into one global search index across entire app.
  + good for generic search page
#Method b. search scope
  Allows you to do more advanced searching against only ONE Active Record class
  + good for autocompleters
  + good for filtering a list of items in faceted search

#Method a. Multi Search
  Create global search index for multiple classes at once
  $rails g pg_search:migration:multisearch
  $ rake db:migrate
  #app/models/one.rb
  class One < ...
    include PgSearch
    multisearchable :against => [:title, :author]
  end
  #app/models/two.rb
  class Two < ...
    include PgSearch
    multisearchable :against => :color
  end
  #1. If model already has existing record, must reindex the mode.l
  #2.  Or The index can also become out-of-sync if you ever modify records in a way that does not trigger Active Record callbacks. For instance, the #update_attribute instance method and the .update_all class method both skip callbacks and directly modify the database.

  #To remove all of the documents for a given class, you can simply delete all of the PgSearch::Document records.

  PgSearch::Document.delete_all(:searchable_type => "Animal")

  #To regenerate the documents for a given class, run:

  PgSearch::Multisearch.rebuild(Product)

  #This is also available as a Rake task, for convenience.

  $ rake pg_search:multisearch:rebuild[BlogPost]

  #NOTE: When record is created, updated, destroyed, an ActiveRecord callback wil fire.
  #ActiveRecord callback => PgSearch::Document record created in pg_search_documents table

  #You could determine whether or not a particular record should be indexed/included
  # => NOTE: The checks are called in an 'after_save' hook

  # => NOTE: careful of Time or other objects. 
  #       If record saved before the published_at timestamp, 
  #       will not be listed in global search at all 
  #       until touched again after the timestamp
            #See https://github.com/Casecommons/pg_search, find 'problematic_record'
  eg) #models/convertible.rb 
  class Convertible < ...
    include PgSearch
    multisearchable :against => [:make, :model],
                    :if => :available_in_red?
    def available_in_red
      colors.include?("red")
    end
  end
  eg) #models/jalopy.rb
  class Jalopy < ...
    include PgSearch
    multisearchable :against => [:make, :model],
                    :if => lambda { |record| record.model_year > 1970}
  end

Multisearch 
I hate to say it but all the other solutions limit your functionality with using prefixes. The proper way is to follow the documentation here: http://www.postgresql.org/docs/9.1/static/textsearch-controls.html

Replace all spaces with "&"

You can do this in your search method:
query = query.split(" ").join(" & ")

Hey Ryan,

Thanks for the great screencast! The solution that I found to your problem with slow rank or weighted search on multiple columns is to create a column to actually use for searching:

Example:
ruby

class AddIndexForFullTextSearch < ActiveRecord::Migration
  def up
    execute "ALTER TABLE users ADD COLUMN tsv tsvector"
    execute <<-QUERY
    UPDATE users SET tsv = (to_tsvector('english', coalesce("building"."first_name"::text, '')) || 
                            to_tsvector('english', coalesce("building"."last_name"::text, '')));
    QUERY
    
    execute "CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE
              ON users FOR EACH ROW EXECUTE PROCEDURE
              tsvector_update_trigger(tsv, 'pg_catalog.english', first_name, last_name);"
  end
  def down
    execute "drop trigger tsvectorupdate on users"
    execute "alter table users drop column tsv"
  end

ruby

class User < ActiveRecord::Base
  include PgSearch
  pg_search_scope :search, against: [:first_name, :last_name], 
    using: {
      tsearch: {
        dictionary: "english",
        tsvector_column: 'tsv'
      }
    }
end

I've tested this solution with 200K records and it makes a significant difference.
Solution was found on "http://linuxgazette.net/164/sephton.html"
'

Using tsvector update trigger in Postgres trigger
#src: http://stackoverflow.com/questions/6784005/using-tsvector-update-trigger-in-postgres-trigger/6802040#6802040
