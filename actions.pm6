unit module action;

class TestActions is export {

    has @contract;
    has @invariants;
    has @constructed_fields;
    has @mutable_fields;
    has @functions;
    has @code_generation_annotated_fields;

    method contract-definition($/) {
      @contract = $/<contract-name>;
    }

    method invariant($/) {
      for $/.<bool-expression-list><expression> -> $match {
        @invariants.push($match)
      }
    }

    method constructed-field-declaration($/) {
        my %value = name => $/<word>, type => $/<type>;
        @code_generation_annotated_fields.push(%value);
        @constructed_fields.push($/.<word>);
    }

    method mutable-field-declaration($/) {
        my %value = name => $/<word>, type => $/<type>;
        @code_generation_annotated_fields.push(%value);
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
    
    method get_contract {
      return @contract;
    }

    method get_invariants {
      return @invariants;
    }

    method get_constructed_fields {
      return @constructed_fields;
    }

    method get_mutable_fields {
      return @mutable_fields;
    }

    method get_functions {
      return @functions;
    }

    method get_code_generation_annotated_fields {
      return @code_generation_annotated_fields;
    }
}
