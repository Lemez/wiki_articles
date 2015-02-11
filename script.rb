# usage - 
# ruby script.rb true/false 
# if you do or don't want to write to file

# require 'httparty'
require 'nokogiri'
require 'google_drive'
require 'CGI'
require 'active_support/all'
require 'net/http'
require 'open-uri'
require 'awesome_print'
require "addressable/uri"
require_relative './lib/uri'
require_relative './lib/string'


# extract band name from spreadsheet
@bands = ["One_Direction","Taylor_Swift","OneRepublic","Sam_Smith_(singer)","Coldplay"]

# get wikipedia articles
@sites = [["simple",'https://simple.wikipedia.org/wiki/'],["english", "https://en.wikipedia.org/wiki/"]] # nb multiple words separated by '_'

def get_bands
	list = "http://en.wikipedia.org/wiki/List_of_Billboard_Hot_100_top_10_singles_in_2013"
	article = open(list)
	result = Nokogiri::HTML(article)
	trs = result.xpath("//td[3]")

	@artists = []

	trs.each do |e| 
		a=e
		b= e.xpath("ancestor::tr/child::td[2]")

		artist = a.xpath("a/@href")
		artist = b.xpath("a/@href") if a.text.upcase==a.text.downcase

		@artists << artist[0].value[6..-1] if artist.length == 1
		artist.each {|v| @artists << v.value[6..-1] } if artist.length == 2
	
	end
	p @artists
	return @artists

end

# determine if we are writing to file or not
@writing = ARGV[0]
# area = ARGV[1]

def get_text para
	 
	return para.gsub!(/\[[0-9]+\]/, "") if para.include?("]")
	return para
	
end

def get_sentences

	@bands.each do |band|
		p "fetching #{band}"
	
		@sites.each do |site|
			begin
				p "fetching #{site[0]}"
				title = site[0] 
				filestring = "./results/music/#{band}-#{title}.txt"

				next if File.exists?(filestring)

				@file = open(filestring, "w") if @writing
				@base_url = site[-1]
				@root = @base_url[@base_url.index('/')+2...@base_url.index('.')]
				url_string = "#{@base_url}#{band}".strip
				article = open(url_string)
				result = Nokogiri::HTML(article)

				result.css('p').each do |para|
					text = get_text(para.content)
					unless text.nil?
						@file.puts(text)
					else
						@file.puts("")
					end
				end
					
				p "completed #{title}"
				p "-------"
				@file.close	if @writing

			rescue OpenURI::HTTPError => e
				if e.message == '404 Not Found'
					p "no luck with #{@base_url}#{band}"
					next
				else
					raise e
				end
			end
		
		end
		p "completed #{band}"
		p "******"
	end
end

# get_sentences

@bands +=get_bands
get_sentences
