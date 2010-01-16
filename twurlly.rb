#!/usr/bin/env ruby

require 'rubygems'
require 'twitter'
require 'net/http'

# Twurl.ly !
class Twurlly
  #twitter has a limit of 3200 tweets stored per person.  
  #this is a hacky starting point that should be generalized
  #to other feeds
  
  @@last_id_checked = 6000000000
  
  #downloads the given url
  def download url
    uri = URI.parse url
    Net::HTTP.start(uri.host) { |http|
      resp = http.get(uri.path)

      #pulls the filename out of the response from the eztv redirect
      #then saves the file to that filename in the current directory
      rxp = Regexp.new(/filename="([^"].*)"/)
      filename = rxp.match(resp['content-disposition'])[1]
      open(filename, "wb"){ |file|
        file.write(resp.body)
      }
    }
  end

  #returns a list of urls to download
  def stalk(user_name, keys, debug)
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
          fn = debug ? method(:puts) : method(:download)
          #pattern match from http:// up to the next white space
          fn.call(text[/http:(\/{2})(\S*)/])
        end
      end
    end
  end
end

if __FILE__ == $0
  begin
    ts0 = Twurlly.new
    ts0.stalk("eztv_it", ["nip","grey"], true)
  end
end
