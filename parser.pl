use lib '.';
use grammar;
use actions;

my $fh = open "test.yas", :r;
my $test = $fh.slurp;
$fh.close;

my $actions = TestActions.new;
my $parse_tree = Lang.parse($test, actions => $actions);
my $code_generation_fields_template = sub ($type, $name) { return '\qq[$type.lc()] \qq[$name]; ' }
my $code_generation_function = sub ($name) { return ' function \qq[$name] { }'}

my $generated_code = '';

my $contract = $actions.get_contract;
my @code_generation_annotated_fields = $actions.get_code_generation_annotated_fields;
my @functions = $actions.get_functions;

$generated_code = $generated_code ~ 'contract \qq[$contract]  {  ';
for @code_generation_annotated_fields -> $val {
  $generated_code = $generated_code ~ $code_generation_fields_template($val<type>, $val<name>);
}
for @functions -> $val {
  for $val<contract-fn-block><fn-block><fn-body><expression> -> $expr {
    say $expr;
  }
}
$generated_code = $generated_code ~ '}';

my $output = open "output_example.sol", :w;
$output.print($generated_code);
$output.close;
