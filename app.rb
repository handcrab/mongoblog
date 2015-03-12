require 'sinatra'
require 'slim'

get '/' do
  @title = 'hello world!'
  slim :index
end

__END__
@@ index
doctype html
html
  head
    title Sinatra With Slim
  body
    h1= @title
