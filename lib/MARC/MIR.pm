package MARC::MIR;
use Modern::Perl;
use parent 'Exporter';

# ABSTRACT: DSL to manipulate MARC Intermediate Representation 
our $VERSION = '0.0';


our @EXPORT_OK = qw<
    iso2709_records_of
    from_iso2709
    to_iso2709
    for_humans

    with_fields
    with_those_subfields
    map_fields
    map_those_subfields
    grep_fields
    grep_those_subfields
    any_fields
    any_those_subfields

    tag
    value

    with_value
    is_control
    record_id
    ready_to_see

>;


our %EXPORT_TAGS = ( all => \@EXPORT_OK );
our $RS = "\x1d";
our $FS = "\x1e";
our $SS = "\x1f";

sub iso2709_records_of (_) {
    open my $fh, shift;
    sub {
	local $/ = $RS;
	<$fh> // ();
    }
}

sub ready_to_see (_) {
    s/$ISO2709::FS/$ISO2709::FS\n/g;
    $_
} 

sub _fold_indicators {
    my $ind = shift or return "  ";
    ref $ind ? @$ind : $ind
}

sub to_iso2709 (_) {
    # adapted from Frederic Demian's MARC::Moose serializer

    my $rec = shift;
    my (@directory,@data);
    my $from = 0;

    # TODO: middleware anaromy_check (control fields)
    # TODO: is serialization a middleware ? 
    for my $field ( @{ $$rec[1] } ) { # TODO: use map_fields ? :)
	# my ( $tag, $data, $indicator ) = @$field;
	my $last;
	my $raw = do {
	    if ( ref $$field[1] ) { # data field
		$last = pop @{ $$field[1] };
	        join '' 
	        , # TODO: is *this* a middleware ? 
		    ( map { ref $_ ? @$_ : $_ } ($$field[2] ||= [' ',' '] ) )
	        , $SS
	        , map( { @$_, $SS } @{ $$field[1] } )
	        , @$last
	        , $FS
	    }
	    else { # control field
	        $$field[1] . $FS;
	    }
	};
	$last and push @{ $$field[1] }, $last;

	my $len = bytes::length( $raw );
	push @data, $raw;
	push @directory
	, sprintf( "%03s%04d%05d", $$field[0], $len, $from );

	$from+=$len;
    }

    my $offset = 24 + 12 * @{ $$rec[1] } + 1;
    my $length = $offset + $from + 1;

    # $length > 9999 and die "$length bytes is too long for a marc record";

    for ( $$rec[0] ) {
	substr($_, 0, 5)  = sprintf("%05d", $length);
	substr($_, 12, 5) = sprintf("%05d", $offset);
	# Default leader various pseudo variable fields
	# Force UNICODE MARC21: substr($$rec[0], 9, 1) = 'a';
	# those are defaults described at http://archive.ifla.org/VI/3/p1996-1/uni.htm
	substr($_, 10, 2) = '22';
	substr($_, 20, 4) = '4500';
    }

    join ''
    , $$rec[0]
    , @directory
    , $FS
    , @data
    , $RS
}


sub _field {
    my ( $tag ) = @_;
    my @chunks = split /\x1f(.)/;
    if ( @chunks == 1 ) { [ $tag, @chunks ] }
    else {
	my @subfields;
	my $indicators = [split //, shift @chunks];
	while (@chunks) {
	    push @subfields, [splice @chunks,0,2];
	}
	[ $tag, \@subfields, $indicators ]
    }
}

sub from_iso2709 (_) {
    my $raw = shift;
    chop $raw;
    my ( $head, @fields ) = split /\x1e/, $raw;
    @fields or die;
    $head =~ /(.{24})/cg or die;
    my $leader = $1;
    my @tags = $head =~ /\G(\d{3})\d{9}/cg;
    unless ( $head =~ /\G$/cg ) {
	die "head tailing ".( $head =~ /(.*)/cg );
    }
    [ $leader
    , [ map {_field( shift @tags )} @fields ]
    ];
}

sub _control_field_for_human {
    ref $$_[1] 
    ? ()
    : "$$_[0] $$_[1]"
}

sub _data_field_for_human {
    my ($tag, $subfields, $indicators) = @$_;
    ref $subfields or return (); # probably a control field
    join ''
    , $tag
    , '(' , _fold_indicators( $indicators ) , ') '
    , map {
	' $'
	, $$_[0]
	, ' '
	, $$_[1]
    } @$subfields
}

sub for_humans (_) {
    my $record = shift;
    join "\n"
    , $$record[0]
    , map {
	_control_field_for_human ||
	_data_field_for_human    || die YAML::Dump { "can't humanize ", $_ }
    } @{ $$record[1]}
}


sub tag   (_) { @{ shift() }[0] }
sub value (_) { @{ shift() }[1] }

sub _use_arg   { push @_, $_ unless @_ > 1 }

sub _with_data {
    &_use_arg;
    my ( $code, $on ) = @_;
    map { $code->() } $$on[1];
}

sub _map_data {
    &_use_arg;
    my  ( $code, $on ) = @_;
    map { $code->() } 
	ref  $$on[1]
	? @{ $$on[1] }
	:    $$on[1]
}

sub _any_data {
    &_use_arg;
    my  ( $code, $on ) = @_;
    map {
	my $r = $code->();
	$r and return $r;
    } 
	ref  $$on[1]
	? @{ $$on[1] }
	:    $$on[1]
    ;
    ()
};

sub _grep_data {
    &_use_arg;
    my  ( $code, $on ) = @_;
    grep { $code->() } 
	ref  $$on[1]
	? @{ $$on[1] }
	:    $$on[1]
}

sub with_fields              (&;$) { &_with_data  }
sub with_those_subfields     (&;$) { &_with_data  }
sub map_fields               (&;$) { &_map_data   }
sub map_those_subfields      (&;$) { &_map_data   }
sub grep_fields              (&;$) { &_grep_data  }
sub grep_those_subfields     (&;$) { &_grep_data  }
sub any_fields               (&;$) { &_any_data   }
sub any_those_subfields      (&;$) { &_any_data   }

sub with_value (&;$) {
    my $code = shift;
    my $r    = @_ ? shift : $_;
    ( map $code->(), $$r[1] )[0];
}

sub is_control (_) {
    my $r = shift;
    @$r == 2;
}

sub record_id (_) {
    my $rec = shift;
    any_fields { tag eq '001' and value };
}

1;

