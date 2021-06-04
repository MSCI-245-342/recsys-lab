require 'sequel'
require 'tty-prompt'

prompt = TTY::Prompt.new
DB = Sequel.connect(adapter: :postgres, database: 'bookratings' )

title = prompt.ask( "Enter a string to search for a book by title." ) do |q|
  q.required true # user has to enter something
  # remove extra whitespace and downcase
  q.modify :trim, :collapse, :down
end

title_search = DB.fetch( "select * from books where lower(title) like ? order by title", "%#{title}%" ) 

if title_search.count > 1
  puts "There are multiple book titles containing that string."

  choices = [] # an array of hashes. Each hash is a choice.
  title_search.each do |row|
    choices << { name: row[:title], value: row[:id] }
  end

  book_id = prompt.select("Which book? (type to search, enter to select) ", choices, filter: true, per_page: 10 ) 
else
  puts "I'm sorry, but there are not any matching books."
  exit(1)
end

# remove this line, it is for demo purposes only
puts "book_id = #{book_id}"

































