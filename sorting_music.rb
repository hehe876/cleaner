
begin
  gem "echowrap"
  gem "taglib"
  gem "httparty"
rescue LoadError
  system("gem install echowrap")
  system("gem install taglib-ruby")
  system("gem install httparty")
  Gem.clear_paths
end

require 'echowrap'
require 'taglib'
require 'json'
require 'net/http'
require 'httparty'

API_KEY = "4MC33PKU1MHMO55TC"
CONSUMER_KEY = "4321382ba6abbc68c7c4f29792b8590d"
SHARED_SECRET = "bQddLRGtSaOV/zWHS9os0A"

Echowrap.configure do |config|
  config.api_key =       API_KEY
  config.consumer_key =  CONSUMER_KEY
  config.shared_secret = SHARED_SECRET
end


def analyse_file(location)    
        
    response = Echowrap.track_upload(:track => File.new(location), :filetype => 'mp3')
    title = response.title
    artist = response.artist

    uri = URI('https://api.spotify.com/v1/search')
    params = { :q => title + " artist:"+ artist, :type => "track" }
    uri.query =  URI.encode_www_form(params)

    response = JSON.parse(Net::HTTP.get(uri))


    album = response['tracks']['total'] > 0 && response['tracks']['items'][0]['album'] && response['tracks']['items'][0]['album']['name'] ? response['tracks']['items'][0]['album']['name'] : ''
    image_url = response['tracks']['total'] > 0  && response['tracks']['items'][0]['album']['images'].size > 0 ? response['tracks']['items'][0]['album']['images'][0]['url'] : ''   
    track = response['tracks']['total'] > 0 && response['tracks']['items'][0]['track_number'] ? response['tracks']['items'][0]['track_number'] : 0

    TagLib::MPEG::File.open(location) do |mp4|          
        tag = mp4.id3v2_tag
        tag.title  = title
        tag.artist = artist
        tag.album = album        
        tag.track = track 

        File.open("/tmp/music_cover_picture.jpg", "wb") do |f| 
            f.binmode
            f.write HTTParty.get(URI(image_url)).parsed_response
        end

        apic = TagLib::ID3v2::AttachedPictureFrame.new
        apic.mime_type = "image/jpeg"
        apic.description = "Cover"
        apic.type = TagLib::ID3v2::AttachedPictureFrame::FrontCover
        apic.picture = File.open("/tmp/music_cover_picture.jpg", 'rb') { |f| f.read }
        tag.add_frame(apic)
        mp4.save
        File.rename(location, artist + " - " + title + File.extname(location))
    end
    
end

analyse_file("21_Miley_Cyrus-The_Climb.mp3")