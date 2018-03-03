require 'uri'
require 'net/http'
require 'json'
require './Movie'
require './Director'
require './Constants'

COUNTRY_CODES = Hash.new ()
COUNTRY_CODES['china'] = 'CN'
COUNTRY_CODES['germany'] = 'DE'
COUNTRY_CODES['greece'] = 'GR'
COUNTRY_CODES['italy'] = 'IT'
COUNTRY_CODES['japan'] = 'JP'
COUNTRY_CODES['russia'] = 'RU'
COUNTRY_CODES['spain'] = 'ES'
COUNTRY_CODES['united kingdom'] = 'UK'
COUNTRY_CODES['united states'] = 'US'

puts 'Enter the country/market for movies from below (all lower case)'

COUNTRY_CODES.each do |country, code|
  puts country
end

COUNTRY_CODE = COUNTRY_CODES[gets.chomp.downcase] #'GR' #greece
#puts COUNTRY_CODE

URL_ROOT = 'https://api.themoviedb.org/3'
API_KEY = Constants.API_KEY
IMDB_URL = 'http://www.imdb.com/name/'

def makeRequest(url)
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(url)
  request["content-type"] = 'application/json'
  response = http.request(request)
end

url = URI(URL_ROOT+"/discover/movie?api_key="+API_KEY+"&region="+COUNTRY_CODE)


response = makeRequest(url)

#print response
#puts response.read_body.force_encoding('ISO-8859-1')
#puts JSON.pretty_generate(JSON.parse(response.read_body))

results = JSON.parse(response.read_body)['results']

movieList = []

#https://www.tutorialspoint.com/ruby/ruby_iterators.htm
results.each do |result|
  
  # get IMDB link
  url = URI(URL_ROOT + '/movie/'+ result['id'].to_s + '/credits?api_key=' + API_KEY)
  #puts url.host+"#{url.path}?#{url.query}##{url.fragment}"
  response = makeRequest(url)
  # credits = JSON.parse(response.read_body)

  #puts credits

  crews = JSON.parse(response.read_body)['crew']
  # puts crews
  directors = []

  unless crews.nil?
    crews.each do |crew|
      if (crew['job'].include? 'Director') && crew['department'] == "Directing"
        puts crew['name'] + ' : ' + crew['job']
          url = URI(URL_ROOT+'/person/'+crew['id'].to_s+'?api_key=731bbf2ec9bb063616f264ddaf44010f')
          
          response = makeRequest(url)
          imdb_id = JSON.parse(response.read_body)['imdb_id']
          
          if imdb_id.nil? || imdb_id == ''
            imdb_id = ''
          else imdb_id = IMDB_URL+imdb_id
          end
          
          directors.insert(0, Director.new(crew['name'], imdb_id))
        end
      
    end
  end

  # add to movieList
  movieList.insert(0, Movie.new(result['title'], result['overview'], result['original_title'], 
    directors)


  # movieList.add( new Movie(result['title'], result['overview'], result['original_title'], 
  #   directors ))

  )
end

insertMoviesStatements = []
insertDirectorsStatements = []

# print each movie
movieList.each do |movie|
  #puts movie.title + ':' + movie.description 
  insertMoviesStatements.insert(0,
   "INSERT INTO MOVIES (title, description, original_title) VALUES ('" + movie.title + "','" + movie.description.gsub("'", "''") + "','" + movie.original_title + "');")

  movie.directors.each do |director|
    insertDirectorsStatements.insert(0,
      "INSERT INTO Directors (name,imdb, title ) values ('" +
        director.name+ "', '"+ director.imdb + "','" + movie.title+ "');")
  end
end

File.open('Queries.sql', 'w'){ |file| file.write(
  'DROP TABLE IF EXISTS MovieDirectors;'\
  "\n"\
  'DROP TABLE IF EXISTS movies cascade;'\
  "\n"\
  'DROP TABLE IF EXISTS Directors cascade;'\
  "\n"\
  'create table movies( id serial primary key,'\
    'description varchar(4000),'\
    'title varchar(200),'\
    'original_title varchar(200)'\
  ');'\
  "\n"\
  'create table Directors('\
    'id serial primary key,'\
    'name varchar(100),'\
    'imdb varchar(150),'\
    'title varchar(200)'\
  ');'\
  "\n" + insertMoviesStatements.join("\n") + insertDirectorsStatements.join("\n") 
  # + "\n" + "create table MovieDirectors(
  #   mid int references movies(id),
  #   did int references Directors(id)  
  # );
    
  # insert into MovieDirectors(mid, did)
  # select m.id, d.id
  # from movies m inner join directors d
  # on m.title = d.title;

  # alter table directors drop column title;

  # select * from movies m 
  # full join moviedirectors md on m.id = md.mid
  # full join directors d on md.did = d.id;"
)}

# File.open("RunQueries.sh", "w") { |file| file.write(
#   'psql -f Queries.sql'
# ) }

puts "SQL file loaded. Run queries? (Y/N)"

wantsExecuteSQL = gets.chomp
if wantsExecuteSQL.downcase == 'y'
  puts 'Is your PostgreSQL server running?'
  if gets.chomp.downcase == 'y'
    # t = Thread.new do
    #   exec 'brew services start postgres'
    # end
    exec 'psql -f Queries.sql'#'chmod a+x RunQueries.sh && ./RunQueries.sh'
  else puts "Start PostgreSQL and execute the following command:

    psql -f Queries.sql"
  end
end 


# save to database
#zetcode.com/db/postgresqlruby
# begin
  
#   con = PG.connect :dbname => 'aaa'
#   puts con.server_version

#   con.exec 'DROP TABLE IF EXISTS movies;'
#   con.exec 'create table movies('
#   'id int primary key,
#   description varchar(4000),
#   title varchar(200),
#   original_title varchar(200),
#   );'

#   insertStatements.each do |sqlStatement|
#     con.exec sqlStatement
#   end
  

# rescue PG::Error => e 
#   puts e.message

# ensure
#   con.close if con
  
# end