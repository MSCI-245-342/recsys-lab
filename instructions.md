# Lab - Using Databases from Programs

Issuing SQL queries to a database is cool, but it is even cooler to be able to write programs that use a database for storage.

In this lab, we're going to walk through a simple way to run SQL queries from a ruby program, and then give you a chance to add some features to the program.

## To Get Started

`cd` into the git repo directory you have created by cloning the lab's repo.

## Bundler

Programming languages like Ruby and Python are great because there are lots of existing open source code to use.  For Ruby, this code is packaged up into "gems".  Each gem can depend on other gems, which can depend on other gems, etc.  

Without a special tool, it would be complex to manage all of the dependencies needed for a project.  Thanksfully, [Bundler](https://bundler.io/) makes dependency management easy.

In the file `Gemfile`, you'll see:

```ruby
source 'https://rubygems.org'

gem 'sequel'
gem 'tty-prompt'
```

Here we're telling Bundler that we need to use the `sequel` and the `tty-prompt` gems.  Bundler will go to rubygems.org to get the latest versions of these gems for us.

To install the gems and their dependencies, do:
```
bundle install
```
and Bundler will make sure you have the gems installed.

## Sequel

Each programming language will have one or more ways to connect and query databases.  For Ruby, we will use [Sequel](http://sequel.jeremyevans.net/) when writing two-tier applications and [ActiveRecord](https://guides.rubyonrails.org/active_record_basics.html) as part of Rails (three-tier web apps).

Since you now know SQL, you can quickly get up to speed with Sequel.  You can [read here about how to issue and process SQL queries with Sequel](http://sequel.jeremyevans.net/rdoc/files/doc/sql_rdoc.html), but we'll provide a brief tutorial below to get you started quickly.

### Connecting to the database

The first thing to do, when writing a database app, is to figure out how to connect to the database.

Create a new file named `examples.rb` and put into it the following:
```ruby
require 'sequel'
```
This statement will search an include path of locations for Ruby code.  This path includes where we installed the sequel gem, and thus we'll find sequel and bring its functionality into our program.

Then, on the next line add:
```ruby
DB = Sequel.connect(adapter: :postgres, database: 'bookratings' )
```
This will use Sequel to connect to our bookratings database.  If you look at the documentation for [Sequel.connect](http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html), you will see there are lots of options that we have not included because the default work for our setup.  In particular, missing are a username and password for the database.  On Codio, we have setup postgres to work with the `codio` username and to not have a password.  If you worked in another environment that was shared with other people or open to the whole internet, this of course would be a foolish thing, for your database would be at risk of accidental or purposeful changes.

In the above code, we use an all-CAPS variable name `DB`.  This makes `DB` a constant in Ruby.  This is suggested by Sequel since we'll only have one connection to the database from our program.  

### Bookratings DB

To refresh your memory of the bookratings DB, do:
```
psql -d bookratings
```
and then in psql, do `\d books` to see what the books table looks like.  To see all tables, do `\d` by itself.

Once you've done this, quit psql with `\q`.

### SQL select

It is easy to run a SQL query and get the results. Each row is a hash where the keys are the column names and the values are the row's values for those columns.

Add the following to your code:
 
```ruby
results = DB.fetch( "select * from books where id < 5" ) 
puts "What the rows looks like in ruby:"
results.each do |row|
  p row
end
```

The above code runs the SQL query, and then iterates through the rows that are returned.

Run your code: `ruby examples.rb` .  The code above uses the `p` function to pretty-print the `row` data structure for us.

You should see output like:
```ruby
What the rows looks like in ruby:
{:id=>1, :title=>"The Hitchhiker's Guide To The Galaxy", :author=>"Douglas Adams"}
{:id=>2, :title=>"Watership Down", :author=>"Richard Adams"}
{:id=>3, :title=>"The Five People You Meet in Heaven", :author=>"Mitch Albom"}
{:id=>4, :title=>"Speak", :author=>"Laurie Halse Anderson"}
```

As you can see, each row is a hash, for example:
```ruby
{:id=>24, :title=>"Brave New World", :author=>"Aldous Huxley"}
```

The keys of the hash are ruby symbols: `:id`, `:title`, and `:author`.

To access the id of a book, we'd do `row[:id]`. So, here we can output the books in a nicer fashion.

```ruby
puts
puts "Nicely formatted output:"
results.each do |row|
  puts "\"#{row[:title]}\" by #{row[:author]}"
end
```

Add the above to your code and run it again.

### Queries with Arguments

When we write interactive apps that get input from users, we'll want to issue SQL queries with this data.  For example, a user might want to search for a particular book title.  To do this search, we'll to ask the user for a string and then incorporate that string into our SQL query.

It is very tempting to use [ruby string interpolation](http://ruby-for-beginners.rubymonstas.org/bonus/string_interpolation.html) to put user specified data into our queries, but that is a huge security threat.  

![](https://imgs.xkcd.com/comics/exploits_of_a_mom.png)

The above cartoon illustrates the risk of [SQL Injection](https://en.wikipedia.org/wiki/SQL_injection).  The most important thing you need to know about SQL injection is to always use the proper way to supply arguments to your SQL queries based on the library you are using to connection and query to the database.  

Never use string interpolation with SQL queries!

We must always "sanitize" the user input to make sure it cannot be used for a SQL injection attack.  

In Sequel, we do this with question marks in our query and then supplying arguments to the query that are matched up in order with the question marks.

For example:
```ruby
title = "series"  # assume entered by user
title_search = DB.fetch( "select * from books where lower(title) like ? order by title", "%#{title}%" ) 
```

Each question mark in our query string is replaced with the next argument to the fetch method call.  We can use multiple question marks.

String comparison in a postgres DB is case sensitive.  To find a match, we need to downcase (lower) the strings in the database and lower the input string, too.

Once we start "composing" SQL queries with arguments, it can be very helpful for debugging to see the query that Sequel creates:
```ruby
puts "title_search.sql = \"#{title_search.sql}\""
```

We can even check to see the number of rows returned:
```ruby
puts "The number of rows, title_search.count = #{title_search.count}"
```
Let's print out the rows:
```ruby
puts "Here are the matching books:"
puts
title_search.each do |row|
  puts "\"#{row[:title]}\" by #{row[:author]}"
end
puts
```
Add the above code to your program and run it.

### Changing the database

We can also insert, update, and delete data from the database.  

#### The `tty-prompt` gem

Writing code to prompt the user for input is tedious.  There is a great gem to help us writing interactive command line programs in ruby: `tty-prompt` [documentation](https://github.com/piotrmurach/tty-prompt).

At the top of your code, add:
```ruby
require 'tty-prompt'
```

Then back at the bottom add:
```ruby
prompt = TTY::Prompt.new 

puts "Please give me a title and author of a book you'd like to add to the database."
new_book = prompt.collect do
  key(:title).ask("Title?")
  key(:author).ask("Author?")
end

insert_book = DB["insert into books (title, author) values (?,?)", 
                 new_book[:title], new_book[:author] ]
insert_book.insert
```

Run the code, and add a book title and its author that you personally like.

Now, run `psql -d bookratings` and verify that you were able to insert your book into the books table.  Note that it has its own unique id.

See the [Sequel documentation](http://sequel.jeremyevans.net/rdoc/files/doc/sql_rdoc.html#label-INSERT-2C+UPDATE-2C+DELETE) for examples of DELETE and UPDATE.

## Tasks

In the file `bookinfo.rb`, we have some code that will allow a user to search for an select a book based on its title.  Go ahead and run it: `ruby bookinfo.rb`

You are to finish this program by printing out a "page" about the book with the following information:

1. The book's title and author, clearly identified as such.

1. The number of ratings the book has received.

1. The book's average rating.

1. A list of at most 5 users who are fans of the book.  To be a fan, a user has to rate the book a 5.  The limit the number of rows, you use SQL [LIMIT](https://www.postgresql.org/docs/current/queries-limit.html).  Clearly identify your list as "Fans of this book include:" and print the users' names, but not their ids.

### Challenge Task

This is optional, but very cool.  

For the fans of the book, get all of their bookratings, get the average rating for each book, and for books with an average fan rating of > 4.0, list them as "Fans of this book, also like these books:".  Note: you are only using the ratings of these fans and not all ratings.

For this challenge task, it is up to you how much you want to do with SQL, and how much you want to do in Ruby.  For example, you don't have to use SQL to compute the averages, but maybe that is easier than computing the averages in Ruby.

To make this feature even better, add in a measure of "minimal support", i.e. you only include books in the list that have at least 2 fans liking them.  

# Turning in your work

Edit the README.md file to include your name.

Commit and push your code to GitHub.
























