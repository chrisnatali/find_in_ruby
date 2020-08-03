# FindInRuby

Tools for finding static dependencies between Ruby methods.  For instance, if you have a problematic method `problem_method` and want to determine the methods that rely on it, you can do the following:

## Generate method relationships csv

For each ruby file in your codebase do:
`find_method_calls.rb <ruby_file>` >> method_calls.csv

Output:

CSV with fields

`method_name,caller_name,caller_type,module_name,calling_method_name,class_name,filename,line_number`

Example:

`ruby find_method_calls.rb example_with_method.rb`

outputs:

```
puts,,,::method1,,example_with_method.rb,3
method1,MyModule,const,,,example_with_method.rb,7
```

## Query for method dependencies

`cat method_calls.csv | ruby query_method_dependencies.rb -mproblem_method > dependencies.csv`


