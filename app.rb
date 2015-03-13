require 'sinatra'
require 'slim'
require 'mongo'

include Mongo

configure do
  # conn = MongoClient.new 'localhost', 27017
  # set :mongo_connection, conn
  # set :mongo_db, conn.db('blog')
  # posts_collection = mongo_db.collection('posts')
  set :mongo_db, MongoClient.new.db('blog')
  set :posts_collection, settings.mongo_db.collection('posts')
  settings.posts_collection.create_index({ permalink: Mongo::ASCENDING },
                                         unique: true)
end

# model
class Post
  @collection = Sinatra::Application.settings.mongo_db.collection 'posts'

  class << self
    def all
      @collection.find.sort created_at: :desc # cursor
    end

    def create(post)
      post['permalink'] = permalink_or_value post['permalink'],
                                             valid_permalink_from(post['title'])
      # raise if @collection.find_one permalink: post['permalink'] # unique?
      post['tags'] = prepare_tags post['tags']
      new_id = @collection.insert post.merge(created_at: Time.now)
      @collection.find_one(_id: new_id)
    rescue Mongo::OperationFailure
      nil
    end

    def find_by_permalink(permalink)
      @collection.find_one permalink: permalink
    end

    def update(permalink, post)
      post['tags'] = prepare_tags post['tags']
      # post['permalink'] = permalink_or_value post['permalink'], permalink
      @collection.update({ permalink: permalink }, '$set' => post)
    rescue Mongo::OperationFailure
      nil
    end

    def delete_by_permalink(permalink)
      @collection.remove permalink: permalink
    end

    def find_by_tag(tag)
      @collection.find(tags: tag).sort created_at: :desc
    end

    def add_comment(permalink, comment)
      @collection.update({ permalink: permalink },
                         '$push' => { comments: comment })
    end

    def increment_comment_likes(permalink, comment_ordinal)
      comment_id = "comments.#{comment_ordinal}.likes"
      @collection.update({ permalink: permalink },
                         '$inc' => { comment_id => 1 })
    end

    # helpers
    def valid_permalink_from(value)
      value.strip.gsub(/\s+/, '_').downcase
    end

    def permalink_or_value(permalink, value)
      return value if permalink.nil? || permalink.strip.empty?
      valid_permalink_from permalink
    end

    def prepare_tags(tag_str)
      tag_str.split(',').map { |t| t.strip.downcase }.uniq
    end
  end
end

get '/' do
  @title = 'Welcome to My Blog'
  @posts = Post.all.limit 10
  slim :index
end

get '/posts/new' do
  @post = {}
  slim :new
end

post '/posts' do
  @post = Post.create params[:post]
  if @post
    redirect "/posts/#{@post['permalink']}"
  else
    params[:post].delete 'permalink' # reset permalink on error
    @post = params[:post]
    slim :new
  end
end

get '/posts/:permalink' do
  @post = Post.find_by_permalink params[:permalink]
  slim :show
end

get '/posts/:permalink/edit' do
  @post = Post.find_by_permalink params[:permalink]
  slim :edit
end

patch '/posts/:permalink' do
  params[:post].delete 'permalink' # dont update permalink
  @post = Post.update params[:permalink], params[:post]
  if @post
    redirect "/posts/#{params[:permalink]}"
  else
    @post = params[:post].merge permalink: params[:permalink]
    slim :edit
  end
end

delete '/posts/:permalink' do
  @post = Post.delete_by_permalink params[:permalink]
  redirect '/'
end

get '/tags/:tag' do
  @title =  "Posts by #{params[:tag]}"
  @posts = Post.find_by_tag params[:tag] # URI.escape
  slim :index
end

post '/comments' do
  post = Post.find_by_permalink params[:permalink]
  redirect '/' unless post # post not found

  post_path = "/posts/#{params[:permalink]}"
  redirect post_path if params[:comment][:body].strip.empty?

  Post.add_comment params[:permalink],
                   params[:comment].merge(created_at: Time.now)
  redirect post_path
end

patch '/comments/like' do
  Post.increment_comment_likes params[:permalink], params[:comment][:ordinal]
  redirect "/posts/#{params[:permalink]}"
end
