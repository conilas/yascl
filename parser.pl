use lib '.';
use grammar;

my @constructed_fields;
my @mutable_fields;
my @functions;

class TestActions {
    method constructed-field-declaration($/) {
        @constructed_fields.push($/.<word>);
    }

    method mutable-field-declaration($/) {
        @mutable_fields.push($/.<word>);
    }

    method constructor-contract-delcaration($/) {
      my @mutations;
      my @mutated;
      my @constructions;
      my @constructed;
      my @executed_mutations;

      for $/.<contract-fn-block><mutates-construct> -> $mutates {
          for $mutates.<word-list>.<word> -> $word {
            if $word eq any(@mutable_fields) {
                @mutations.push($word)
            } elsif $word eq any(@constructed_fields) {
                @constructions.push($word)
            } else {
              die $word ~ " not in mutable fields. Did you forget to create the field?"
            }
          }
      }

      for $/.<contract-fn-block><fn-block><fn-body><expression> -> $expression {
        when $expression<value-assignment><self-assignment> {
          if !($expression<value-assignment><self-assignment><word> eq any(@mutations)) and
             !($expression<value-assignment><self-assignment><word> eq any(@constructions)) {
            die $expression<value-assignment><self-assignment><word> ~
                " mutated but not annotated in mutations. Did you forget to add a 'mutations' clause?";
          } else {
            if ($expression<value-assignment><self-assignment><word> eq any(@constructions)) {
              @constructed.push($expression<value-assignment><self-assignment><word>)
            } else {
              @mutated.push($expression<value-assignment><self-assignment><word>)
            }
          }
        }
      }

      my @should_have_constructed =  @constructions.grep({ ! ($_  eq any(@constructed))});

      if @should_have_constructed.any() {
        die "The following values were not mutated, but where in the mutation contract. Have you forgotten to mutate them? [" ~
            @should_have_constructed ~ "] ";
      }
    }

    method common-constructor-function-declaration($/) {
      my @mutations;
      my @executed_mutations;

      for $/.<contract-fn-block><mutates-construct> -> $mutates {
          for $mutates.<word-list>.<word> -> $word {
            if $word eq any(@mutable_fields) {
                @mutations.push($word)
            } else {
              die $word ~ " not in mutable fields. Did you forget to create the field?"
            }
          }
      }

      for $/.<contract-fn-block><fn-block><fn-body><expression> -> $expression {
        when $expression<value-assignment><self-assignment>  {
          if !@mutations.first($expression<value-assignment><self-assignment><word>) {
            die $expression<value-assignment><self-assignment><word> ~
                " mutated but not annotated in mutations. Did you forget to add a 'mutations' clause?";
          }
        }
      }

      @functions.push($/)
    }
}

my $fh = open "test.yas", :r;
my $test = $fh.slurp;
$fh.close;

my $parse_tree = Lang.parse($test, actions => TestActions.new);
