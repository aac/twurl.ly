#!/usr/bin/env ruby

require 'rubygems'
require 'twitter'
require 'net/http'

class TweetStalker
  # this is a hack.  timeline fails on since_id 0, and we subtract 1 in order to make sure we've got all the missing tweets
  @@last_id_checked = 6000000000

  def download file
    Net::HTTP.start("static.flickr.com") { |http|
      resp = http.get("/92/218926700_ecedc5fef7_o.jpg")
      
      #open("fun.jpg", "wb") { |file|
      #file.write(resp.body)
      #}
    }

  end

  #returns a list of urls to download
  def stalk(user_name, keys)
    timeline = []
    page = 1
    hit_limit = false
    #force it
    oldest_id_received = @@last_id_checked + 1

    until hit_limit || @@last_id_checked > oldest_id_received do
      timeline_page = Twitter::timeline(user_name, :page => page, :count => 200, :since_id => (@@last_id_checked - 1))
      hit_limit = timeline_page.size == 0

      timeline.concat timeline_page 
      page += 1
      oldest_id_received = timeline.last[:id]      
    end

    urls = []
    timeline.each do |tweet|
      text = tweet[:text].downcase
      keys.each do |key|
        if (text.include? key.downcase)
          puts text[/http:(\/{2})(\S*)/]
        end
      end
    end
  end
end

if __FILE__ == $0
  begin
    ts0 = TweetStalker.new
    ts0.stalk("eztv_it", ["nip","grey"])
  end
end
