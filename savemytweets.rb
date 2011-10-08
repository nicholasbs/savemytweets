#!/usr/bin/env ruby

require 'twitter'
require 'mongo'
require './settings.rb'

Twitter.configure do |config|
  config.consumer_key = CONSUMER_KEY
  config.consumer_secret = CONSUMER_SECRET
end

options = {
  :include_rts => true,
  :trim_user => true,
  :count => 100, # fails less often than asking for the max (200)
  :page => 1
}

username = "nicholasbs"

begin 
  db = Mongo::Connection.new(MONGO_HOST, MONGO_PORT).db('savemytweets')
rescue
  $stderr.puts "Error: Could not connect to mongo (#{MONGO_HOST} on port #{MONGO_PORT}). Have you started mongod?"
  exit(1)
end
coll = db.collection(username)

# Get the id of the newest tweet we've saved
res = coll.find_one(:newest_tweet_id => {'$exists' => true})
# Only ask for tweets since the last one we saved
options[:since_id] = res['newest_tweet_id'] unless res.nil?

tweets = []

batch = Twitter.user_timeline(username, options)
tweets += batch
options[:page] += 1
puts "batch size: #{batch.length}"

until batch.size < options[:count]
  begin 
    batch = Twitter.user_timeline(username, options)
  rescue Twitter::ServiceUnavailable
    # Try once more before giving up.
    batch = Twitter.user_timeline(username, options)
  end

  tweets += batch
  options[:page] += 1
  puts "batch size: #{batch.length}"
end

unless tweets.empty?
  puts "New tweets to save"
  newest_tweet_id = tweets.first['id_str']

  # Save the tweets
  coll.insert(tweets)

  # Save the id of the newest tweet we've saved
  if options[:since_id]
    puts "previous tweet id found, updating..."
    coll.update({:newest_tweet_id => options[:since_id]}, {:newest_tweet_id => newest_tweet_id})
  else
    puts "no tweet id found, inserting..."
    coll.insert('newest_tweet_id' => newest_tweet_id)
  end
end
