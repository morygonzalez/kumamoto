require "rubygems"
require "oauth"
require "pit"
require "json"

while true
  begin
    config = Pit.get("kumamoto", :require => {
      "consumer_key" => "consumer key",
      "consumer_secret" => "consumer secret",
      "access_token" => "access token",
      "access_token_secret" => "access token secret"
    })
    c = OAuth::Consumer.new(
      config["consumer_key"],
      config["consumer_secret"],
      :site => "http://twitter.com"
    )
    t = OAuth::AccessToken.new(
      c,
      config["access_token"],
      config["access_token_secret"]
    )
    JSON.parse(t.get("/statuses/user_timeline.json?count=200").body).each do |p|
      puts "#{p["id"]}: #{p["text"]}"
      if p["text"] =~ /^@[^ningengasinu]/
        p t.post("/statuses/destory/#{p["id"]}.json") rescue nil
      end
    end
    sleep 60
  rescue
    sleep 20
  end
end
