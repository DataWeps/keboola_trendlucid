require 'json'
require 'typhoeus'

TABLES = %w(products reviews comments).freeze

def download_file(name)
  file = File.open(filename(name), 'wb')
  request = Typhoeus::Request.new(
    "#{CONFIG['api_url']}/#{name}",
    userpwd: "#{CONFIG['username']}:#{CONFIG['password']}")
  request.on_headers do |response|
    raise 'Request failed' if response.code != 200
  end
  request.on_body do |chunk|
    file.write(chunk)
  end
  request.on_complete do
    file.close
  end
  request.run
end

def fetch_files
  TABLES.each do |name|
    tries = 5
    begin
      download_file(name)
    rescue => exception
      unless exception.to_s == 'Request failed'
        STDERR.puts exception.message
        Kernel.exit(-1)
      end
      if tries == 0
        Kernel.abort("Downloading #{name} failed! Check API URL and credentials.")
      end
      tries -= 1
      retry
    end
  end
end

def check_files
  TABLES.each do |name|
    Kernel.abort("#{filename(name)} missing!") unless File.file?(filename(name))
  end
end

def filename(name)
  "#{ENV['KBC_DATADIR']}out/tables/#{CONFIG['table_prefix']}.#{name}"
end

begin
  CONFIG =
    JSON.parse(File.read("#{ENV['KBC_DATADIR']}config.json"))['parameters']
rescue StandardError
  Kernel.abort('No configuration file, or it is missing API parameters.')
end
fetch_files
check_files
