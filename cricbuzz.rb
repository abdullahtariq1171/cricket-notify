require 'nokogiri'
require 'httparty'

def escape(string)
  pattern = /(\'|\"|\.|\*|\/|\-|\\|\)|\$|\+|\(|\^|\?|\!|\~|\`)/
  string.gsub(pattern){|match|"\\"  + match}
end

CRICBUZZ_URL = 'http://synd.cricbuzz.com/j2me/1.0/livematches.xml'
page = HTTParty.get(CRICBUZZ_URL)
last_modified = page.headers['last-modified']
puts page.body[0..50]
puts last_modified

opts = {"if-modified-since" => last_modified}

page_again = HTTParty.get(CRICBUZZ_URL, :headers => opts)
puts '*'*30
puts page_again.to_s
puts '()'*30
puts page_again.body
puts page_again.headers
puts '()'*30

exit

page = Nokogiri::XML(page.body)
r1 = HTTParty.get("http://orgmode.org/org.html")


# page = Nokogiri::XML(open('temp.txt'))
page.xpath("./mchdata/match").each do |match|
	next if ['Result', 'stump'].include? match.xpath("./state/@mchState").text.to_s
	match_detail = match.xpath("./mscr")

	bowl_team_name = match_detail.xpath("./blgTm/@sName").text
	bat__team_name = batTM.xpath("./@sName").text


	batTM = match_detail.xpath("./btTm")
	inning         =  batTM.xpath("./Inngs")
	runs           = inning.xpath("./@r").text
	wkts           = inning.xpath("./@wkts").text
	ovrs           = inning.xpath("./@ovrs").text

	score = escape "#{runs}/#{wkts} (#{ovrs} Ovs)"
	summary = "#{bat__team_name} vs #{bowl_team_name}"
	body =  "#{score}"
	command = "notify-send #{summary.gsub(/ /, '\ ')} #{body.gsub(/ /, '\ ')} --expire-time=1"
	puts command
	`#{command}`
end
