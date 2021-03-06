require 'json'
require 'typhoeus'

TABLES = %w(products reviews shops).freeze
API_URL = 'https://api.trendlucid.com'.freeze
LANGUAGES = %w(com de).freeze
MANIFEST = { incremental: true, primary_key: %w(id) }.freeze

def download_file(name, language)
  file = File.open(filename(name, language), 'wb')
  url = "#{API_URL}/#{name}?lang=#{language}"
  url += '&all=true' if CONFIG['all']
  request = Typhoeus::Request.new(
    url,
    userpwd: "#{CONFIG['username']}:#{CONFIG['password']}"
  )
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
    LANGUAGES.each do |language|
      tries = 5
      begin
        download_file(name, language)
      rescue => exception
        unless exception.to_s == 'Request failed'
          STDERR.puts "#{exception.class}: #{exception.message}"
          STDERR.puts exception.backtrace
          Kernel.exit(-1)
        end
        if tries == 0
          Kernel.abort(
            "Downloading #{language}_#{name} failed! "\
            'Check API URL and credentials.'
          )
        end
        tries -= 1
        retry
      end
    end
  end
end

def create_manifest
  Dir["#{ENV['KBC_DATADIR']}out/tables/*.csv"].each do |table|
    File.open("#{table}.manifest", 'w') { |file| file << MANIFEST.to_json }
  end
end

def filename(name, language)
  "#{ENV['KBC_DATADIR']}out/tables/out.c-trendlucid.#{language}_#{name}.csv"
end

begin
  CONFIG = JSON.parse(File.read("#{ENV['KBC_DATADIR']}config.json"))['parameters']
rescue StandardError
  Kernel.abort('No configuration file, or it is missing API parameters.')
end
fetch_files
create_manifest
