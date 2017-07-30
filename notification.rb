require './os.rb'
require './utility.rb'

class Notification
  class << self
    def push(summary, body, timeout=1)
      if OS.mac?
        # osascript -e 'display notification "Hello world!" with title "Hi!"'
        # -open 'https://github.com/abdullahtariq1171/' -sound 'default'
        command = "terminal-notifier -title '#{summary}' -message '#{body}'"
      else
        command = "notify-send #{summary.gsub(/ /, '\ ')} #{(Utility::escape body).gsub(/ /, '\ ')} --expire-time=1"
      end
      puts "Command is '#{command}'"
      `#{command}`
    end
  end
end
