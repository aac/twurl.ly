#!/usr/bin/env ruby

require 'rubygems'
require 'twitter'
require 'net/http'
require 'json'

# Twurl.ly !
class Twurlly
  #twitter has a limit of 3200 tweets stored per person.  
  #this is a hacky starting point that should be generalized
  #to other feeds
  DATA_FILE = "twurlly.dat"

  attr_reader :last_id_checked

  def self.get
    if File.exists?(DATA_FILE)
      File.open(DATA_FILE) {|file|
        Marshal.load(file)
      }
    else
      Twurlly.new
    end
  end
    
  
  def initialize
    @last_id_checked = 6000000000
  end
  
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
  
  def process_timeline(timeline, patterns, debug)
    timeline.each do |tweet|
      text = tweet['text'].downcase
      patterns.each do |key|
        key = key.downcase if key.respond_to? :downcase
        if (text.match key)
          if debug
            puts text
          else
            download(text[/http:(\/{2})(\S*)/])
          end
        end
      end
    end

    @last_id_checked = timeline.first[:id] unless timeline.empty?
  end
  
  def get_timeline(user_name)
    timeline = []
    page = 1
   hit_limit = false
    #force it
    oldest_id_received = @last_id_checked + 1

    until hit_limit || @last_id_checked > oldest_id_received do
      timeline_page = Twitter::timeline(user_name, :page => page, :count => 200, :since_id => (@last_id_checked - 1))
      hit_limit = timeline_page.size == 0

      timeline.concat timeline_page 
      page += 1
      oldest_id_received = timeline.last[:id]      
    end

    timeline
  end

  def stalk(user_name, patterns, debug)
    timeline = get_timeline(user_name)
    process_timeline(timeline, patterns, debug)
  end
end

if __FILE__ == $0
  begin
    ts0 = Twurlly::get

    user_name = "eztv_it"
    keys = ["nip tuck", "grey's anatomy", "house"]
    patterns = keys.map {|key| eval("/^%s\\s+s\\d+e\\d+/i" % key)}

      ts0.stalk(user_name, patterns, true)
      File.open(Data_file, 'w') { |f|
          Marshal.dump(ts0, f)
        }
  end
end
