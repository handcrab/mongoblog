require 'sinatra'
require 'slim'

get '/' do
  @title = 'My Blog'
  slim :index
end
