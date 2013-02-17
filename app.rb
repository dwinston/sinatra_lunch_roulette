require 'sinatra'
require "sqlite3"

database_file = settings.environment.to_s+".sqlite3"

db = SQLite3::Database.new database_file
db.results_as_hash = true
db.execute "
	CREATE TABLE IF NOT EXISTS users (
		email VARCHAR(100),
		time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		visit_counter INTEGER DEFAULT '1' 
	);
";

get '/' do
	erb File.read('our_form.erb')
end

post '/' do
	@email = params['email'].downcase
	result = db.execute("SELECT * FROM users WHERE email = ?", @email) || []
	if result.length>0 #this field checks to see if a record already exists based on that email address
		@visit_counter = result.shift['visit_counter'] + 1
		db.execute("
		UPDATE users 
		SET time = datetime('now'), visit_counter = ?
		WHERE email = ?
		", @visit_counter, @email);
	else
		@visit_counter = 1 #in the future, we may want to revisit this visit counter getting set to 1 
		db.execute(
			"INSERT INTO users(email) VALUES ( ?)",
			@email
		);
	end
	erb File.read('thanks.erb')
end


#create session so users are remembered on the site.

get '/users/:email' do

	@email = params['email']
	@messages = db.execute("
		SELECT * FROM users 
		JOIN users 
		ON users.id = users.user_id 
		WHERE email = ?
	", params['email'])

	erb File.read('user.erb')

end

get '/users/:email/edit' do

	@email = params['email']
	result = db.execute("SELECT * FROM users WHERE email = ?", params['email'])
	@user = result.shift || false
	erb File.read('user_edit.erb')

end

post '/users/:old_email' do

	db.execute("
		UPDATE users SET email = ? WHERE email = ?;
	", params['email'], params['old_email'])

end

# Create a new user (email, password)
post '/users/' do
  db.execute("INSERT into users(email, password) VALUES (?, ?)",
             params['email'], params['password'])
end

# Login the user (email, password)
post '/login' do
  @email = params['email']
  result = db.execute("SELECT * FROM users WHERE email = ? and password = ?", 
                      @email, params['password']) || []
  if result.length>0
    erb File.read('welcome.erb')
  end
end
