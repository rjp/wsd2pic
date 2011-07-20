print <<PROLOGUE;
.PS
copy "sequence.pic";
PROLOGUE

my %object_names = (); # global list of object names
my @objects = (); # ordered list of object names
my %alive = (); # which lanes are alive

# record an object in our list if we've not seen it before
sub object {
    my $name = shift;
    if (not defined $object_names{$name}) {
        push @objects, $name;
        $object_names{$name} = 1;
    }
}

while (<>) {
    # simple message
    if (/^(.+?)(->|-->)(.+?): (.+)/) {
        object($1); object($3);
        
        if ($2 eq '->') {
            push @output, ['message', qq/message($1,$3,"$4")/];
        }
        if ($2 eq '-->') {
            push @output, ['message', qq/rmessage($1,$3,"$4")/];
        }
    }

    # object is alive
    if (/^activate\s+(.+)/) {
        object($1);
        push @output, ['lifetime', qq/active($1)/];
        $alive{$1} = 1;
    }

    # object is not alive
    if (/^deactivate\s+(.+)/) {
        object($1);
        push @output, ['lifetime', qq/inactive($1)/];
        delete $alive{$1};
    }

    # object gets a destroy message
    if (/^destroy\s+(.+)/) {
        object($1);
        push @output, ['lifetime', qq/inactive($1)/];
        push @output, ['destroy', qq/delete($1)/];
        delete $alive{$1};
    }
}

my $previous = undef;
foreach my $i (@objects) {
    print qq/object($i,"$i");\n/;
}
print "step();\n";

foreach my $i (@output) {
    my ($type, $outline) = @{$i};
    print $outline, ";\n";
    if ($type =~ /message$/) {
        if ($previous =~ /message$/) {
            print "step();\n";
        }
    }
    $previous = $type;
}

# deactivate any alive objects just for clean output
foreach my $i (keys %alive) {
    print qq/inactive($i);\n/;
}

# and a final step for spacing
print "step();\n";

# extend all the swimlanes downwards
foreach my $i (@objects) {
    print qq/complete($i);\n/;
}

print <<EPILOGUE;
.PE
EPILOGUE

# print STDERR join(', ', @objects), "\n";
