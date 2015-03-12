require 'sinatra'
require 'slim'
require 'mongo'
require 'json/ext' # required for .to_json

include Mongo

configure do
  conn = MongoClient.new 'localhost', 27017
  set :mongo_connection, conn
  set :mongo_db, conn.db('blog')
end

get '/' do
  @title = 'My Blog'
  slim :index
end
