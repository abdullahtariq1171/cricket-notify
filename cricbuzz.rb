require 'nokogiri'
require 'httparty'
require './notification.rb'


CRICBUZZ_URL = 'http://synd.cricbuzz.com/j2me/1.0/livematches.xml'
opts = {}
while true
	response = HTTParty.get(CRICBUZZ_URL, headers: opts)
	case (response.code.to_i)
		when 304
			puts "Not Modified Yet #{response.headers['last-modified']}"
		when 200
			puts "Modified #{response.headers['last-modified']}"
			opts = {"if-modified-since" => response.headers['last-modified']}
			response = Nokogiri::XML(response.body)
			response.xpath("./mchdata/match").each do |match|
				next if ['Result'].include? match.xpath("./state/@mchState").text.to_s
				match_detail   = match.xpath("./mscr")

				batTM  = match_detail.xpath("./btTm")
				inning = batTM.xpath("./Inngs")
				runs   = inning.xpath("./@r").text
				wkts   = inning.xpath("./@wkts").text
				ovrs   = inning.xpath("./@ovrs").text

				bowl_team_name = match_detail.xpath("./blgTm/@sName").text
				bat__team_name = batTM.xpath("./@sName").text

				body = "#{runs}/#{wkts} (#{ovrs} Ovs)"
				summary = "#{bat__team_name} vs #{bowl_team_name}"
				Notification.push(summary, body)
				# exit
				break
			end
		else
			puts "Something else happened"
	end
end
