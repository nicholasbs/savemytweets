require 'trollop'
require 'twitter'
require 'mongo'

module SaveMyTweets
  class Command
    USAGE_STRING = "usage: savemytweets [--mongo-port] [--mongo-host] USERNAME"

    attr_reader :args
    def initialize(*args)
      @args = args
      @options = {
        :include_rts => true,
        :trim_user => true,
        :count => 100, # fails less often than asking for the max (200)
        :page => 1
      }
    end

    def self.run(*args)
      new(*args).run
    end

    def run
      parser = Trollop::Parser.new do
        version "SaveMyTweets #{SaveMyTweets::VERSION}"
        banner "#{USAGE_STRING}\nOptions:"
        opt :mongo_port, "The port your MongoDB instance is running on",
          :type => :int, :default => 27017
        opt :mongo_host, "The host your MongoDB instance is running on",
          :type => :string, :default => "localhost"
      end

      @global_opts = Trollop::with_standard_exception_handling parser do
        o = parser.parse @args
        @username = @args[0]
        raise Trollop::HelpNeeded if ARGV.empty? or @username.nil?
        o
      end

      connect_to_db!
      tweets = download_tweets!
      write_to_db! tweets unless tweets.empty?
    end

    private
    def download_tweets!
      # Get the id of the newest tweet we've saved
      res = @coll.find_one(:newest_tweet_id => {'$exists' => true})
      # Only ask for tweets since the last one we saved
      @options[:since_id] = res['newest_tweet_id'] unless res.nil?
      tweets = []

      begin 
        batch = get_next_batch!
        tweets += batch
        puts "batch size: #{batch.length}"
      end until batch.size < @options[:count]

      tweets
    end

    def write_to_db!(tweets)
      newest_tweet_id = tweets.first['id_str']

      @coll.insert(tweets) # save the tweets

      # Save the id of the newest tweet we've saved
      if @options[:since_id]
        @coll.update({:newest_tweet_id => @options[:since_id]}, {:newest_tweet_id => newest_tweet_id})
      else
        @coll.insert('newest_tweet_id' => newest_tweet_id)
      end
    end

    def get_next_batch!
      batch = []
      begin
        batch = Twitter.user_timeline(@username, @options)
      rescue # Try once more before giving up.
        batch = Twitter.user_timeline(@username, @options)
      end
      @options[:page] += 1
      batch
    end

    def connect_to_db!
      begin 
        @db = Mongo::Connection.new(@global_opts[:mongo_host], @global_opts[:mongo_port]).db('savemytweets')
        @coll = @db.collection(@username)
      rescue
        $stderr.puts "Error: Could not connect to mongo (#{@global_opts[:mongo_host]} on port #{@global_opts[:mongo_port]}). Have you started mongod?"
        exit(1)
      end
    end
  end
end
