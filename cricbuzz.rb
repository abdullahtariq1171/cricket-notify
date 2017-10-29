require 'nokogiri'
require 'httparty'
require './notification.rb'


class CricBuzz
	CRICBUZZ_URL = 'http://synd.cricbuzz.com/j2me/1.0/livematches.xml'
	IGNORE_MATCH_STATUS = ['result', 'stump', 'complete', 'preview']

	def initialize
		@headhers  = {}
		@following = {}
	end

	def run
		matches_element = Nokogiri::XML(get_latest.body).xpath("./mchdata/match").reject { |match| IGNORE_MATCH_STATUS.include? match.xpath("./state/@mchState").text.downcase }
		if matches_element.empty?
			puts "No match is live at the moment."
			return
		end

		count = 0
		matches = []

		puts "Enter Match Number you want to follow:\n< separate with comma to follow multiple matches >"
		matches_element.each do |match|
			desc = "#{match.attr('mchDesc')} #{match.attr('mnum')}"
			matches << {id: match.attr('id'), match_str: match.to_s}
			puts "Enter #{count} for #{desc}"
			count += 1
		end

		gets.strip.split(',').map!(&:to_i).each do |index|
			m = matches[index]
			@following[m[:id]] = m[:match_str]
		end

		while true
			case (get_latest.code.to_i)
				when 200
					@headhers = {"if-modified-since" => @response.headers['last-modified']}
					Nokogiri::XML(@response.body).xpath("./mchdata/match").each do |match|
						id = match.attr('id')
						# puts "@following[id] \n***\n\n#{@following[id]}\n***\n#{match.to_s}\n => #{@following[id] != match.to_s}"
						next unless @following.has_key? id
						next unless @following[id] != match.to_s
						# next if match.xpath("./state/@mchState").text.downcase == 'preview' #match has not begun yet

						@following[id] = match.to_s

						match_detail   = match.xpath('./mscr')

						batTM  = match_detail.xpath("./btTm")
						inning = batTM.xpath("./Inngs")
						runs   = inning.attr('r')
						wkts   = inning.attr('wkts')
						ovrs   = inning.attr('ovrs')

						bowl_team_name = match_detail.xpath("./blgTm/@sName")
						bat_team_name = batTM.attr('sName')

						body = "#{bat_team_name} #{runs}/#{wkts} (#{ovrs} Ovs)"
						summary = "#{bat_team_name} vs #{bowl_team_name}"

						push_notification(summary, body)
						# exit
						break
					end
				when 304
					# puts "Not Modified"
				else
					puts "Something else happened"
			end
			sleep 3
		end
	end

	def get_latest
		@response = http.get(CRICBUZZ_URL, headers: @headhers)
		# puts "@response.code.to_i => #{@response.code.to_i}"
		@response
	end

	private
		def http
			@httparty ||= HTTParty
		end

		def push_notification(summary, body)
			puts "#{summary}-#{body}"
			Notification.push(summary, body)
		end

end

CricBuzz.new.run
