require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'fileutils'
require 'zip/zipfilesystem'

# https://www.yifysubtitles.com

def imdb_movie(imdb_code)
  doc = Nokogiri::HTML(open("https://www.yifysubtitles.com/movie-imdb/" + imdb_code))
  puts "Loaded page"
  doc.css(".table tr.high-rating").each_with_index do |table_row, table_row_index|
    # puts table_row.css('flag').to_s
    if table_row.css('.flag').first['class'].include?('flag-gb')
      puts "Found english sub with rating: #{table_row.css('.rating-cell span').text}"
      download_zip("https://www.yifysubtitles.com" + table_row.css('.download-cell a').first['href'])
    end
        
  end
end

def download_zip(link)

  doc = Nokogiri::HTML(open(link))
  
  File.open("./subtitle.zip", "wb") do |file|
    file.write open(doc.css('a.btn-icon.download-subtitle').first['href']).read
  end
  puts "Downloaded"

  Zip::ZipFile.open("./subtitle.zip") { |zip_file|
     zip_file.each { |f|
     f_path=File.join(".", f.name)
     FileUtils.mkdir_p(File.dirname(f_path))
     zip_file.extract(f, f_path) unless File.exist?(f_path)
   }
  }
  puts "Unzipped"

  File.delete("./subtitle.zip") if File.exist?("./subtitle.zip")


end


imdb_movie(ARGV[0])