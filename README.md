Very basic blog app with sinatra and mongodb #learning

## Setup
`bundle install`

run mongodb: 
`mongod --dbpath ~/data/db`

`mongoimport -d blog -c posts < posts.json`

run sinatra app:
`rerun app.rb`