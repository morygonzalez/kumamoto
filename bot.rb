#!/usr/bin/env ruby
require 'tokyotyrant'
require 'rubygems'
require 'oauth'
require 'pit'
require 'json'

class Bot
  include TokyoTyrant

  CONFIG_REQUIRED = [
    'consumer_key',
    'consumer_secret',
    'access_token',
    'access_token_secret',
    'tokyotyrant_hostname',
    'tokyotyrant_port'
  ]

  def initialize(username)
    @behaviors = {}
    @username = username
    @access_token = OAuth::AccessToken.new(
      OAuth::Consumer.new(
        config['consumer_key'],
        config['consumer_secret'],
        :site => 'http://twitter.com'
      ),
      config['access_token'],
      config['access_token_secret']
    )
  end

  def config
    @config ||= Pit.get(@username, :require =>
      Hash[*CONFIG_REQUIRED.map{|c| [c, "#{c} here"]}.flatten]
    )
  end

  def mentions
    json = @access_token.get('http://twitter.com/statuses/mentions.json').body
    JSON.parse(json)
  end

  def reply(proc)
    rdb = RDB.new
    rdb.open(config['tokyotyrant_hostname'], config['tokyotyrant_port'])
    last_reply_id_key = "#{@username}_last_reply_id"
    last_reply_id = rdb[last_reply_id_key]
    replies = mentions.select do |m|
      m['id'] > last_reply_id.to_i
    end
    return if replies == []
    replies.each do |r|
      begin
        if(reply_text = proc.call(r))
          post(proc.call(r),  :in_reply_to_status_id => r['id'])
        end
      rescue LocalJumpError
        next nil
      end
    end
    rdb[last_reply_id_key] = replies.first['id']
    rdb.close
  end

  def tweet(proc)
    if(status = proc.call)
      post(status)
    end
  end

  def hbpost(proc)
    if (status = proc.call)
      post(status)
    end
  end

  def anond(proc)
    if (status = proc.call)
      post(status)
    end
  end

  def city_news(proc)
    if (status = proc.call)
      post(status)
    end
  end

  def post(status, options=nil)
    params = {:status => status}
    params.merge!(options) if options.class == Hash
    @access_token.post('http://twitter.com/statuses/update.json', params)
  end

  def add_behavior(name, proc=nil)
    @behaviors[name] = proc
  end

  def act!
    behavior = ARGV[0].to_sym
    method(behavior).call(@behaviors[behavior])
  end
end
