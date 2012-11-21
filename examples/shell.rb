#!/usr/bin/env ruby -KU

$: << File.dirname(__FILE__) + "/../lib"

require 'runivedo'
require 'rainbow'
require 'readline'
require 'readline/history/restore'
require 'terminal-table'
require 'optparse'

def pluralize(singular, count)
  "#{count} #{singular}#{count != 1 ? 's' : ''}"
end

HIST_FILE = "#{ENV["HOME"]}/.runivedo_history"
Readline::History::Restore.new(HIST_FILE)

def readline_wrapper
  line = Readline.readline('→ '.color(:yellow), true)
  return nil if line.nil?
  if line =~ /^\s*$/ or Readline::HISTORY.to_a[-2] == line
    Readline::HISTORY.pop
  end
  line
end

# Completion
COMPLETION = [
  "add", "aid", "alter", "and", "as", "assign", "avg", "begin", "binaryCond",
  "by", "check", "column", "combine", "commit", "constraint", "count", "create",
  "cross", "delete", "distinct", "drop", "except", "fields", "file", "for",
  "from", "full", "function", "group", "having", "ilike", "in", "inner",
  "insert","into", "is", "join", "jtype", "left", "lift", "like", "max", "min",
  "natural", "not", "not null", "null", "of", "on", "operator", "or", "order",
  "primary key", "query", "release", "res", "right", "rollback", "savepoint",
  "select", "set", "share", "sum", "table", "to", "transaction", "unique",
  "update", "using", "value", "values", "where"
].sort.map(&:upcase)
comp = proc { |s| COMPLETION.grep(/^#{Regexp.escape(s)}/i) }
Readline.completion_append_character = " "
Readline.completion_proc = comp

options = {}
OptionParser.new do |opts|
  opts.on('-h', '--host HOST', "Server url") { |url| options[:url] = url }
  opts.on('-u', '--user USER', "Username") { |user| options[:user] = user }
  opts.on('-p', '--password PASSWORD', "Password") { |password| options[:password] = password }
  opts.on('-f', '--uts UTS', "Path to uts file") { |uts| options[:uts] = uts }

  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
end.parse!

raise "missing host" unless options.has_key? :url
raise "missing user" unless options.has_key? :user
raise "missing password" unless options.has_key? :password
raise "missing uts" unless options.has_key? :uts
options[:uts] = IO.read(options[:uts])

runivedo = Runivedo::Runivedo.new(options)

while line = readline_wrapper
  break if line.nil?
  line.strip!
  case line
  when "q", "quit", "exit"
    break
  when "version", "info", "v"
    puts "Runivedo Shell #{Runivedo::VERSION}"
    puts "(c) 2013 Univedo"
  when "help", "h", "?"
    puts "Runivedo Shell #{Runivedo::VERSION} Help"
    puts "TODO"
  else
    begin
      result = runivedo.execute(line)
      if result.affected_rows
        puts "Updated #{pluralize("row", result.affected_rows)}".color(:green)
      else
        arr = result.to_a
        puts Terminal::Table.new rows: arr, headings: (1..arr.count+1).map { |i| "Row #{i}".bright }
        puts "#{pluralize("row", arr.count)} returned.".color(:green)
      end
    rescue => e
      puts "Caught exception:"
      puts e.to_s.color(:red)  
    end
  end
end

puts
puts "Bye"
