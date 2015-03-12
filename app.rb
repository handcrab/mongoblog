require 'sinatra'
require 'slim'
require 'mongo'
require 'json/ext' # required for .to_json

include Mongo

configure do
  # conn = MongoClient.new 'localhost', 27017
  # set :mongo_connection, conn
  # set :mongo_db, conn.db('blog')
  # posts_collection = mongo_db.collection('posts')
  set :mongo_db, MongoClient.new.db('blog')
end

# model
class Post
  @collection = Sinatra::Application.settings.mongo_db.collection('posts')

  def self.all
    @collection.find.sort created_at: :desc # cursor
  end

  def self.create(post)
    # content_type :json
    new_id = @collection.insert post
    # id = object_id(id) if String === id
    @collection.find_one(_id: new_id)
  end
end

get '/' do
  @title = 'Welcome to My Blog'
  # @post = Post.create title: 'hello', body: 'Hello world', created_at: Time.now
  @posts = Post.all.limit 10
  slim :index
end
