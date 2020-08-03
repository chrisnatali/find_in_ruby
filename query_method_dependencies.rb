#!/usr/bin/env ruby

require 'optparse'
require 'csv'
require 'pry'

options = {}

OptionParser.new do |parser|
  parser.banner = <<~EOF
  Usage: cat csv_file_with_method_calling_method_filename_line_num | query_method_dependencies <method_name> > csv_with_methods_files_lines_that_depend_on_<method_name>
  EOF

  parser.on('-mMETHOD', '--method=METHOD', String, 'The METHOD to find dependencies of') do |v|
    options[:method] = v
  end

  parser.on('-fINPUT_FILE', '--input_file=INPUT_FILE', String, 'Input file') do |v|
    options[:input_file] = v
  end

  parser.on('-oOUTPUT_FILE', '--output_file=OUTPUT_FILE', String, 'Output file') do |v|
    options[:output_file] = v
  end
end.parse!

def read_csv(input)
  csv = CSV.new(input, headers: true, converters: [:numeric])
  rows = []
  csv.each { |row| rows << row }
  rows
end

def write_csv(output, rows)
  csv = CSV.new(output)
  rows.each { |row| csv << row }
end

class DependencyFinder
  def initialize(graph)
    @graph = graph
    @so_far = {}
    @results = []
  end

  def find(method_name, filename, line_number)
    unless @so_far.include?([method_name, filename, line_number])
      @so_far[[method_name, filename, line_number]] = true
      @results << [method_name, filename, line_number]
      if @graph.include?(method_name)
        @graph[method_name].each do |calling_method, filename, line_number|
          find(calling_method, filename, line_number)
        end
      end
    end
  end

  def results
    @results
  end
end

def build_graph(rows)
  graph = {}
  rows.each do |row|
    graph[row['method_name']] ||= []
    graph[row['method_name']] << [row['calling_method_name'], row['filename'], row['line_number']]
  end
  graph
end

if options[:input_file]
  f = File.open(options[:input_file], "r")
else
  f = STDIN
end

graph = build_graph(read_csv(f))
df = DependencyFinder.new(graph)
df.find(options[:method], '', 0)

if options[:output_file]
  f = File.open(options[:output_file], "w")
else
  f = STDOUT
end

write_csv(f, df.results)
f.close
