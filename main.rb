#!/usr/bin/env ruby
# =Weewar Command
# main program without gui
# @markup markdown
# @title Weewar Coammand
# @author Mickael Faivre-Maçon

require 'readline'
require 'weewar'
require 'version'

# = command line to Weewar
class WeewarCommand

  CLIST = [
    'help', 'user', 'ugames', 'gstate', 'games'
    ].sort

  def initialize
    welcome
    @ww = Weewar.new
  end

  def welcome
    puts "Welcome to #{ProgramVersion}\nType 'help' to get... help.\nPress TAB for autocompletion."
  end

  def main
    comp = proc { |s| CLIST.grep( /^#{Regexp.escape(s)}/ ) }
    Readline.completion_append_character = ""
    Readline.completion_proc = comp
    begin
      while input = Readline.readline('>', true)
        begin
          case
          when (input=="quit" or input=="exit")
            exit
          when input=="help"
            print_help
          when input[0..5]=="gstate"
            r = @ww.game_state(input[7..-1])
            puts r.body if r.code=="200"
          when input[0..8]=="ugames"
            puts @ww.user_games(input[10..-1]).join(', ')
          when input=="games"
            puts @ww.games.join(', ')
          when input[0..3]=="user"
            puts @ww.user(input[5..-1]).body
          when input==""
          else
            puts "Unknown command #{input}"
          end
        # inner loop
        rescue  Exception=> e
          puts e
          puts e.backtrace
        end
      end
    # outer loop for readline
    rescue  Interrupt=> e # Ctrl-C
      puts
    rescue  Exception=> e
      puts e
      puts e.backtrace
    end
  end

  def print_help
    welcome
    puts
    puts "Settings"
    puts "========"
    puts "The key.txt file content must be login:key, where login is your bot name ('ai_xxxx') and key your API Key that you got on the Weewar site"
  end

end

WeewarCommand.new.main

