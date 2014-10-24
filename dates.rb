#src: http://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#method-i-date_select
#allows selection of date range, and default, etc.
    <%= f.label :birthday %><br>
    <%= f.date_select :birthday, :start_year => 1830, :end_year => Date.today.year - 10, default: { year: 2000} %>
