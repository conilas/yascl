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

    method contract-fn-declaration($/) {
      my @mutations;

      for $/.<mutates-construct> -> $mutates {
          for $mutates.<word-list>.<word> -> $word {
            if $word eq any(@mutable_fields) {
                @mutations.push($word)
            } else {
              die $word ~ " not in mutable fields. Did you forget to create the field?"
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
