require 'json'
require 'fileutils'
require 'typhoeus'

def download_file(name)
  FileUtils.mkpath "#{ENV['KBC_DATADIR']}/out/tables"
  file = File.open("#{ENV['KBC_DATADIR']}/out/tables/#{name}.csv", 'wb')
  request = Typhoeus::Request.new("#{CONFIG['api_url']}/#{name}",
                                  userpwd: "#{CONFIG['username']}:#{CONFIG['password']}" )
  request.on_headers do |response|
    if response.code != 200
      raise "Request failed"
    end
  end
  request.on_body do |chunk|
    file.write(chunk)
  end
  request.on_complete do |response|
    file.close
  end
  request.run
end

CONFIG = JSON.parse(File.read("#{ENV['KBC_DATADIR']}/config.json"))['parameters']
download_file('products')
download_file('reviews')
download_file('comments')
