package MARC::MIR;
use parent 'Exporter';
use autodie;
use Modern::Perl;
use Perlude;
use Perlude::Sh qw< :all >;
# ABSTRACT: DSL to manipulate MIR records.

=head1 MIR: MARC Intermediate Representation

This is a early adoption code coming with

    * DSL to manipulate MIR records
    * ISO2709 parser
    * ISO2709 writer

perldoc MARC::MIR::tutorial for more information

    * the interface may change
    * t/ is empty, so use it at your own risk

anyway: the MIR itself will not change. 

=cut

our $VERSION = '0.0';

# our %EXPORT_TAGS =
# ( dsl => [qw<
# 	with_fields
# 	with_subfields
# 	map_fields
# 	map_subfields
# 	grep_fields
# 	grep_subfields
# 	any_fields
# 	any_subfields
# 	map_values
# 
# 	tag
# 	value
# 
# 	with_value
# 	is_control
# 	record_id
# 
# 	for_humans
#     >]
# , debug   => [qw< ready_to_see >]
# , iso2709 => [qw< from_iso2709 to_iso2709 iso2709_records_of >]
# , marawk  => [qw< marawk $NUM $RAW $REC $ID %FIELDS >]
# , all => [qw<

our @EXPORT = qw<
	with_fields
	with_subfields
	map_fields
	map_subfields
	grep_fields
	grep_subfields
	any_fields
	any_subfields
	map_values

	tag
	value

	with_value
	is_control
	record_id

	for_humans
	ready_to_see
	from_iso2709 to_iso2709 iso2709_records_of
	marawk $NUM $RAW $REC $ID %FIELDS
    >;
# );
# our @EXPORT_OK = $EXPORT_TAGS{all} = [map @$_, values %EXPORT_TAGS];

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
    state $empty_header = 'x'x24;

    my $rec = shift;
    for ( $$rec[0] ) { length or $_ = $empty_header }
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

	# my $len = bytes::length( $raw );
	my $len = length( $raw );
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
        # xxxxnAxxxxxxxxxxxxxxxx 
        # A:
        # a printed language
        # b manuscript language 
        # c printed scores
        # d manuscript scores 
        # e printed carto
        # f manuscript carto
        # g video
        # i sound
        # j music
        # k tron
        # m multimedia
        # r 3D

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

sub _one_or_array {
    my $r = shift;
    (ref $r) ? @$r : $r
}

sub _map_data {
    &_use_arg;
    my  ( $code, $on ) = @_;
    map { $code->() } _one_or_array $$on[1]
}

sub _any_data {
    &_use_arg;
    my  ( $code, $on ) = @_;
    map {
	my $r = $code->();
	$r and return $r;
    } _one_or_array $$on[1] 
};

sub _grep_data {
    &_use_arg;
    my  ( $code, $on ) = @_;
    grep { $code->() } _one_or_array $$on[1]
}

sub with_fields        (&;$) { &_with_data  }
sub with_subfields     (&;$) { &_with_data  }
sub map_fields         (&;$) { &_map_data   }
sub map_subfields      (&;$) { &_map_data   }
sub grep_fields        (&;$) { &_grep_data  }
sub grep_subfields     (&;$) { &_grep_data  }
sub any_fields         (&;$) { &_any_data   }
sub any_subfields      (&;$) { &_any_data   }

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
    any_fields { tag eq '001' and value } shift;
}

sub map_values (&$;$) {
    my $code = shift or die;
    my ( $fspec, $sspec ) = map { @$_ } (shift or die);
    my $rec  = @_ ? shift : $_;
    map {
	map { with_value {$code->()} }
	    grep_subfields { (tag) ~~ $sspec }
    } grep_fields { (tag) ~~ $fspec }
    # TODO: Benchmark: is it really faster ? 
    # map_fields {
    #     if ( (tag) ~~ $fspec ) {
    #         map_subfields {
    #     	if ( (tag) ~~ $sspec ) {
    #     	    with_value { $code->() }
    #     	} else { () }
    #         }
    #     } else { () }
    # } $rec
}


sub marawk (&$) {
    my ( $code, $glob ) = @_;
    our ( $NUM, $RAW, $REC, $ID, %FIELDS )
    =   ( 0 );
    now {
	$NUM++;
	$RAW = $_;
	$_ = $REC = from_iso2709 $_;
	$ID  = record_id or die "no ID inthere :". for_humans;
	%FIELDS=();

	map_fields {
	    push @{ $FIELDS{(tag)} }
	    , $_
	};

	$code->();
    } concatM {iso2709_records_of} ls $glob
}
1;

