#!/usr/bin/env ruby
$:.unshift(File.dirname(__FILE__))

require 'rubygems'
require 'rss'
require 'open-uri'
require 'json'
require 'bot'
require 'yaml/store'
require 'hpricot'

COMMENTS = YAML.load_file(File.dirname(__FILE__) + '/kumamoto.yml')

class Tweet

  def initialize
    @link = ""
    @comment = ""
  end

  def post
=begin
    used_comments = YAML.load_file(File.dirname(__FILE__) + '/temp.yml')
    if Time.now.hour == 0
      used_comments = []
      db = YAML::Store.new(File.dirname(__FILE__) + '/temp.yml')
      db.transaction do
        db = used_comments
      end
    end
    unless used_comments.nil?
      new_comments = COMMENTS - used_comments
    else
      new_comments = COMMENTS
    end
    @comment = new_comments[rand(new_comments.length)]
    used_comments.push("#{@comment}")
    db = YAML::Store.new(File.dirname(__FILE__) + '/temp.yml')
    db.transaction do
      db = used_comments
    end
=end
    if ARGV.size > 1
      ARGV[1, ARGV.length].each do |a|
        @comment += a + " "
      end
    else
      @comment = COMMENTS[rand(COMMENTS.length)]
    end
    return @comment
  end

  def hbpost
    rss_source = "http://b.hatena.ne.jp/t/%E7%86%8A%E6%9C%AC?sort=eid&mode=rss"
    rss = parse(rss_source)
    item = rss.items[rand(rss.items.length)]
    link = tiny(item.link)
    case item.description
    when /女児/
      @comment = "熊本の最新ロリ情報はこちら"
    when /火事/
      @comment = "ボーボー"
    when /殺人/
      @comment = "大変だ、熊本県民が死んでいるぞ！"
    when /謝罪|人権/
      @comment = "いい加減にして欲しいですね"
    when /男.*女/
      @comment = "熊本の最新即ハメ情報はこちら" 
    when /パワースポット/
      com = %w/熊本の青姦スポット情報です 即ハメスポット@熊本はこちら 恥ずかしいところも丸見えです/
      @comment = com[rand(com.length)]
    when /食|グルメ|おいしい|美味|旨|うまい/
      com = %w/熊本の最新スカトロ情報です 飲尿・糞食は当たり前！ 熊本でも昆虫食がブームです 熊本いい店やれる店/
      @comment = com[rand(com.length)]
    else
      com = %w/うひー あへー んぎもちぃー うけるんですけど 熊本こわい… こらばちかぶる/
      @comment = com[rand(com.length)]
    end
    @link = link["tinyurl"]
    return "#{@comment} #{@link}"
  end

  def city_news
    rss_source = "http://www.city.kumamoto.kumamoto.jp/rss/rss.asp?tid=0"
    rss = parse(rss_source)
    item = rss.items[rand(rss.items.length)]
    link = tiny(item.link)
    @link = link["tinyurl"]
    return "#{item.title} #{@link}"
  end

  def anond
    rss_source = "http://anond.hatelabo.jp/keyword/%E7%86%8A%E6%9C%AC?mode=rss"
    rss = open(rss_source, "User-Agent" => "Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_0 like Mac OS X; en-us) AppleWebKit/528.18 (KHTML, like Gecko) Version/4.0 Mobile/7A341 Safari/528.16")
    doc = Hpricot(rss)
    rdf_lis = doc.search("//rdf:li")
    rdf_li = rdf_lis[rand(rdf_lis.length)]
    url = rdf_li.get_attribute("rdf:resource")
    link = tiny(url)
    @link = link["tinyurl"]
    return "日記書いた #{@link}"
  end

  def reply(r)
    if r['text'].match(/^@kumamoto\s/)
      if /ペプ|行動を?開始|ねる|ねむ|ねて|眠|おやすみ|寝|バタリ|スヤ|ネルソン/ =~ r['text']
        res = %w/とっとと寝ろや 寝るな ぼくもねます なるほど四時起きじゃねーの/
      elsif /(出|で)かける|行く|イク|逝く|昇天|デート/ =~ r['text']
        res = %w/いってらっしゃい それはうらやましい ぼくもでかけます/
      elsif /血が.*出る|失業|原君|痛い|進まない|ハァ|＼\(＾o＾\)／|着る服が無い|あー|ねむい|鬱|ヘルプ|へるぷ|help|諦め|苦しい|つらい|希望がない|だめ|ダメ|駄目|死|しぬ|しにたい|自殺|たすけて|助けて|働きたくない|やだ|むり|無理|やめたい/ =~ r['text']
        res = %w/せからしかばい うるしゃーばい 黙らんと先生に言うばい ぬしゃ舐めとっとや？ ぬしゃくらすっぞ/
      else
        res = %w/燕雀いずくんぞ鴻鵠の志を知らんや はいはい ﾊｲﾊｲ そうですね で？ だけんなん？ ぬしゃなんば言いよっとや？ ボボすっばい/
      end
      "@#{r['user']['screen_name']} #{res[rand(res.length)]}"
    else
      next nil
    end
  end

  private
  def parse(source)
    begin
      RSS::Parser.parse(source, true)
    rescue
      RSS::Parser.parse(source, false)
    end 
  end

  def tiny(link)
    tiny_json = open('http://json-tinyurl.appspot.com/?url=' + link)
    JSON.parse(tiny_json.read)
  end
end

bot = Bot.new('kumamoto') # ボットの Twitter ユーザ名をコンストラクタに与える

bot.add_behavior(:tweet, Proc.new{
  t = Tweet.new
  t.post
})
bot.add_behavior(:hbpost, Proc.new{ 
  t = Tweet.new
  t.hbpost
})
bot.add_behavior(:anond, Proc.new{ 
  t = Tweet.new
  t.anond
})
bot.add_behavior(:city_news, Proc.new{
  t = Tweet.new
  t.city_news
})
bot.add_behavior(:reply, Proc.new{|r|
  t = Tweet.new
  t.reply(r)
})

bot.act!
