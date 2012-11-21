#!/usr/bin/env ruby -wKU

$: << File.dirname(__FILE__) + "/../lib"

require 'runivedo'
require 'rainbow'
require 'readline'
require 'readline/history/restore'

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

  end
end

puts
puts "Bye"
