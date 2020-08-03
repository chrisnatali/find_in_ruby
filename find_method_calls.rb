require 'parser/current'
require 'pry'

class MethodProcessor < AST::Processor

  def initialize(filename)
    @filename = filename
    @class_stack = []
    @module_stack = []
    @method_stack = []
  end

  def on_begin(node)
    node.children.each { |c| process(c) }
  end

  def method_name(def_node)
    def_node.children[0].to_s
  end

  def const_full_name(const_node)
    parent_name = nil
    if !const_node.children[0].nil?
      parent_name = caller_name(const_node.children[0])
    end
    const_name = const_node.children[1].to_s
    parent_name.nil? ? "#{const_name}" : "#{parent_name}::#{const_name}"
  end

  def caller_name(node)
    if node.class <= Parser::AST::Node
      if ([:const].include?(node.type))
        return const_full_name(node)
      elsif ([:lvar].include?(node.type))
        return node.children[0].to_s
      elsif ([:send].include?(node.type))
        return node.children[1].to_s
      else
        return nil
      end
    else
      return node
    end
  end

  def on_send(node, &block)
    caller_node = node.children[0]
    # process parent calls before this one
    process(caller_node) if caller_node.class <= Parser::AST::Node && caller_node.type == :send
    # process parameter nodes before this one
    if node.children.size > 2
      node.children[2..-1].each { |child| process(child) }
    end
    caller_name = caller_name(caller_node)
    caller_type = caller_node.respond_to?(:type) ? caller_node.type : nil
    method_name = node.children[1].to_s
    module_name = @module_stack.empty? ? nil : const_full_name(@module_stack[-1].children[0])
    class_name = @class_stack.empty? ? nil : const_full_name(@class_stack[-1].children[0])
    calling_method_name = @method_stack.empty? ? nil : method_name(@method_stack[-1])
    puts [method_name,caller_name,caller_type,module_name,calling_method_name,class_name,@filename,node.location.line].join(",")
  end

  def on_module(node)
    @module_stack.push(node)
    node.children.each { |c| process(c) }
    @module_stack.pop
  end

  def on_class(node)
    @class_stack.push(node)
    node.children.each { |c| process(c) }
    @class_stack.pop
  end

  def on_def(node)
    @method_stack.push(node)
    node.children.drop(1).each { |c| process(c) }
    @method_stack.pop
  end

  def handler_missing(node)
    node.children.select { |c| c.class <= Parser::AST::Node }.each { |child_node| process(child_node) }
  end
end

filename = ARGV[0]
code = File.read(filename)
ast = Parser::CurrentRuby.parse(code)

processor = MethodProcessor.new(filename)

puts "method_name,caller_name,caller_type,module_name,calling_method_name,class_name,filename,line_number"
processor.process(ast)
