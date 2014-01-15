#! /usr/bin/env ruby

require 'ansi'
require 'open-uri'
require 'nokogiri'
require 'ostruct'

query = URI::encode ARGV.join ' '
url = "http://thepiratebay.se/search/#{query}/0/7/0"

html = open(url, 'Cookie' => 'lw=s')
doc = Nokogiri::HTML html
rows = doc.css '#searchResult tr:not(.header)'

mapping = {
	type:     0,
	name:     1,
	uploaded: 2,
	size:     4,
	seeders:  5,
	leechers: 6
}
results = rows.map do |row|
	cells = row.css('td')
	hash = {}
	mapping.each do |field, index|
		hash[field] = cells[index].content.strip.squeeze(' ')
	end
	hash[:magnet] = cells[3].css('a')[0].attr('href')
	OpenStruct.new(hash)
end

table = results.map.with_index do |result, index|
	[
		index + 1,
		result.name,
		result.type,
		result.uploaded,
		result.size,
		result.seeders,
		result.leechers
	]
end
table.unshift %w(# Name Type Uploaded Size SE LE)

colors = [:white, :yellow, :blue, :blue, :blue, :green, :red]
print(ANSI::Table.new(table) do |_, row, col|
	row.zero? ? :cyan : colors[col]
end.to_s.ansi(:cyan))

print 'Enter a number: '
index = STDIN.gets.chomp.to_i - 1
return unless result = results[index]

`open #{result.magnet}`
