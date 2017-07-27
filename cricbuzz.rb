require 'nokogiri'
require 'httparty'


def escape(string)
  pattern = /(\'|\"|\.|\*|\/|\-|\\|\)|\$|\+|\(|\^|\?|\!|\~|\`)/
  string.gsub(pattern){|match|"\\"  + match}
end


CRICBUZZ_URL = 'http://synd.cricbuzz.com/j2me/1.0/livematches.xml'
# page = Nokogiri::XML(HTTParty.get(CRICBUZZ_URL).body)

page = Nokogiri::XML(open('temp.txt'))
page.xpath("./mchdata/match").each do |match|
	next if ['Result', 'stump'].include? match.xpath("./state/@mchState").text.to_s
	match_detail = match.xpath("./mscr")
	batTM = match_detail.xpath("./btTm")
	bat__team_name = batTM.xpath("./@sName").text
	inning         =  batTM.xpath("./Inngs")
	runs           = inning.xpath("./@r").text
	wkts           = inning.xpath("./@wkts").text
	ovrs           = inning.xpath("./@ovrs").text

	score = escape "#{runs}/#{wkts} (#{ovrs} Ovs)"
	bowl_team_name = match_detail.xpath("./blgTm/@sName").text
	summary = "#{bat__team_name} vs #{bowl_team_name}"
	body =  "#{score}"
	command = "notify-send #{summary.gsub(/ /, '\ ')} #{body.gsub(/ /, '\ ')} --expire-time=2"
	puts command
	`#{command}`
end
