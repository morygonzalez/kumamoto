#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'json'
require 'hpricot'

rss_source = "http://anond.hatelabo.jp/keyword/%E7%86%8A%E6%9C%AC?mode=rss"
rss = open(rss_source, "User-Agent" => "Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_0 like Mac OS X; en-us) AppleWebKit/528.18 (KHTML, like Gecko) Version/4.0 Mobile/7A341 Safari/528.16")
doc = Hpricot(rss)
links = doc.search("//rdf:li")
link = links[rand(links.length)]
url = link.get_attribute("rdf:resource")
tiny_json = open('http://json-tinyurl.appspot.com/?url=' + url)
link = JSON.parse(tiny_json.read)
@link = link["tinyurl"]
puts "日記書いた #{@link}"

