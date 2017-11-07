require 'httparty'
require 'yaml'
require './notification.rb'

class CricBuzz
  CRICBUZZ_URL = 'http://synd.cricbuzz.com/j2me/1.0/livematches.xml'
  IGNORE_MATCH_STATUS = ['result', 'stump', 'complete', 'preview']

  def initialize(config_file)
    @headers  = {}
    @following = {}
    @config = YAML.load_file(config_file)
  end

	def run
		response_json = get_latest.parsed_response['mchdata']

		matches = response_json['match']

		matches.reject! { |match| IGNORE_MATCH_STATUS.include? match['state']['mchState'].downcase }
		matches.each { |match| p "match #{match['mchDesc']} ->#{match['state']['mchState'].downcase}<-"}

		if matches.empty?
			puts "No match is live at the moment."
			return
		end

		count = 0
		matches_arr = []

		puts "Enter Match Number you want to follow:\n< separate with comma to follow multiple matches >"
		matches.each do |match|
			desc = "#{match['mchDesc']} #{match['mnum']}"
			matches_arr << {id: match['id'], match_str: match.to_s}
			p "Enter #{count} for #{desc}"
			count += 1
		end

		gets.strip.split(',').map!(&:to_i).each do |index|
			m = matches_arr[index]
      @following[m[:id]] = m[:match_str]
		end

		while true
			case (get_latest.code.to_i)
				when 200
					@headers = {"if-modified-since" => @response.headers['last-modified']}
					puts "200 => @headers: #{@headers}"
					matches = @response.parsed_response['mchdata']['match'].select { |match| @following.has_key? match['id']}
					matches.each do |match|
						id = match['id']
						next if match['state']['mchState'].downcase == 'preview' #match hasn't begun yet
						puts "id #{id} => Changed? #{@following[id] != match.to_s}"
						next if @following[id] == match.to_s #nothing changed, same as previous

						match_detail   = match['mscr']

						batTM  = match_detail['btTm']
						inning = batTM['Inngs']
						runs   = inning['r']
						wkts   = inning['wkts']
						ovrs   = inning['ovrs']

						bowl_team_name = match_detail['blgTm']['sName']
						bat_team_name = batTM['sName']

						body = "#{bat_team_name} #{runs}/#{wkts} (#{ovrs} Ovs)"
						summary = "#{bat_team_name} vs #{bowl_team_name}"

						push_notification(summary, body)
						@following[id] = match.to_s
					end
				when 304
					puts "304 => @headers: #{@headers}"
				else
					puts "Something else happened"
			end
			sleep @config['SLEEP_DELAY']
		end
	end

  def get_latest
    @response = http.get(CRICBUZZ_URL, headers: @headers)
  end

  private
    def http
      @httparty ||= HTTParty
    end

    def push_notification(summary, body)
      Notification.push(summary, body)
    end

end

CricBuzz.new('config.yml').run
