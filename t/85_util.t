#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    if ($] < 5.008002) {
        plan skip_all => "This test unit requires perl-5.8.2 or higher";
        }
    else {
	plan tests => 206;
	}

    use_ok "Text::CSV_XS";
    require Encode;
    require "t/util.pl";
    }

$| = 1;

ok (my $csv = Text::CSV_XS->new, "new for header tests");
is ($csv->sep_char, ",", "Sep = ,");

my $hdr_lc = [qw( bar foo )];

foreach my $sep (",", ";") {
    my $data = "bAr,foo\n1,2\n3,4,5\n";
    $data =~ s/,/$sep/g;

    $csv->column_names (undef);
    {   open my $fh, "<", \$data;
	ok (my $slf = $csv->header ($fh), "header");
	is ($slf, $csv, "Return self");
	is ($csv->sep_char, $sep, "Sep = $sep");
	is_deeply ([ $csv->column_names ], $hdr_lc, "headers");
	is_deeply ($csv->getline ($fh), [ 1, 2 ],    "Line 1");
	is_deeply ($csv->getline ($fh), [ 3, 4, 5 ], "Line 2");
	}

    $csv->column_names (undef);
    {   open my $fh, "<", \$data;
	ok (my @hdr = $csv->header ($fh), "header");
	is_deeply (\@hdr, $hdr_lc, "Return headers");
	}

    $csv->column_names (undef);
    {   open my $fh, "<", \$data;
	ok (my $slf = $csv->header ($fh), "header");
	is ($slf, $csv, "Return self");
	is ($csv->sep_char, $sep, "Sep = $sep");
	is_deeply ([ $csv->column_names ], $hdr_lc, "headers");
	is_deeply ($csv->getline_hr ($fh), { bar => 1, foo => 2 }, "Line 1");
	is_deeply ($csv->getline_hr ($fh), { bar => 3, foo => 4 }, "Line 2");
	}
    }

my $sep_ok = [ "\t", "|", ",", ";", "##", "\xe2\x81\xa3" ];
foreach my $sep (@$sep_ok) {
    my $data = "bAr,foo\n1,2\n3,4,5\n";
    $data =~ s/,/$sep/g;

    $csv->column_names (undef);
    {   open my $fh, "<", \$data;
	ok (my $slf = $csv->header ($fh, $sep_ok), "header with specific sep set");
	is ($slf, $csv, "Return self");
	is (Encode::encode ("utf-8", $csv->sep), $sep, "Sep = $sep");
	is_deeply ([ $csv->column_names ], $hdr_lc, "headers");
	is_deeply ($csv->getline ($fh), [ 1, 2 ],    "Line 1");
	is_deeply ($csv->getline ($fh), [ 3, 4, 5 ], "Line 2");
	}

    $csv->column_names (undef);
    {   open my $fh, "<", \$data;
	ok (my @hdr = $csv->header ($fh, $sep_ok), "header with specific sep set");
	is_deeply (\@hdr, $hdr_lc, "Return headers");
	}

    $csv->column_names (undef);
    {   open my $fh, "<", \$data;
	ok (my $slf = $csv->header ($fh, $sep_ok), "header with specific sep set");
	is ($slf, $csv, "Return self");
	is (Encode::encode ("utf-8", $csv->sep), $sep, "Sep = $sep");
	is_deeply ([ $csv->column_names ], $hdr_lc, "headers");
	is_deeply ($csv->getline_hr ($fh), { bar => 1, foo => 2 }, "Line 1");
	is_deeply ($csv->getline_hr ($fh), { bar => 3, foo => 4 }, "Line 2");
	}
    }

for ( [ 1010, 0, qq{}		],	# Empty header
      [ 1011, 0, qq{a,b;c,d}	],	# Multiple allowed separators
      [ 1012, 0, qq{a,,b}	],	# Empty header field
      [ 1013, 0, qq{a,a,b}	],	# Non-unique headers
      [ 2027, 1, qq{a,"b\nc",c}	],	# Embedded newline binary on
      [ 2021, 0, qq{a,"b\nc",c}	],	# Embedded newline binary off
      ) {
    my ($err, $bin, $data) = @$_;
    $csv->binary ($bin);
    open my $fh, "<", \$data;
    my $self = eval { $csv->header ($fh); };
    is ($self, undef, "FAIL for '$data'");
    ok ($@, "Error");
    is (0 + $csv->error_diag, $err, "Error code $err");
    }
{   open my $fh, "<", \"bar,bAr,bAR,BAR\n1,2,3,4";
    $csv->column_names (undef);
    ok ($csv->header ($fh, { fold => "none" }), "non-unique unfolded headers");
    is_deeply ([ $csv->column_names ], [qw( bar bAr bAR BAR )], "Headers");
    }
{   open my $fh, "<", \"bar,bAr,bAR,BAR\n1,2,3,4";
    $csv->column_names (undef);
    ok (my @hdr = $csv->header ($fh, { fold => "none" }), "non-unique unfolded headers");
    is_deeply (\@hdr, [qw( bar bAr bAR BAR )], "Headers from method");
    is_deeply ([ $csv->column_names ], [qw( bar bAr bAR BAR )], "Headers from column_names");
    }

foreach my $sep (",", ";") {
    my $data = "bAr,foo\n1,2\n3,4,5\n";
    $data =~ s/,/$sep/g;

    $csv->column_names (undef);
    {   open my $fh, "<", \$data;
	ok (my $slf = $csv->header ($fh, { columns => 0 }), "Header without column setting");
	is ($slf, $csv, "Return self");
	is ($csv->sep_char, $sep, "Sep = $sep");
	is_deeply ([ $csv->column_names ], [], "headers");
	is_deeply ($csv->getline ($fh), [ 1, 2 ],    "Line 1");
	is_deeply ($csv->getline ($fh), [ 3, 4, 5 ], "Line 2");
	}
    $csv->column_names (undef);
    {   open my $fh, "<", \$data;
	ok (my @hdr = $csv->header ($fh, { columns => 0 }), "Header without column setting");
	is_deeply (\@hdr, $hdr_lc, "Headers from method");
	is_deeply ([ $csv->column_names ], [], "Headers from column_names");
	}
    }

for ([ undef, "bar" ], [ "lc", "bar" ], [ "uc", "BAR" ], [ "fc", "bar" ], [ "none", "bAr" ]) {
    my ($fold, $hdr) = @$_;

    my $data = "bAr,foo\n1,2\n3,4,5\n";

    $] < 5.016 && defined $fold and $fold =~ s/^fc/lc/;

    $csv->column_names (undef);
    open my $fh, "<", \$data;
    ok (my $slf = $csv->header ($fh, { fold => $fold }), "header with fold ". ($fold || "undef"));
    is (($csv->column_names)[0], $hdr, "folded header to $hdr");
    close $fh;

    $csv->column_names (undef);
    open $fh, "<", \$data;
    ok (my @hdr = $csv->header ($fh, { fold => $fold }), "header with fold ". ($fold || "undef"));
    is ($hdr[0], $hdr, "folded header to $hdr");
    }

my $fnm = "_85hdr.csv"; END { unlink $fnm; }
$csv->binary (1);
$csv->auto_diag (9);
my $str = qq{zoo,b\x{00e5}r\n1,"1 \x{20ac} each"\n};
for (	[ "none"       => ""	],
	[ "utf-8"      => "\xef\xbb\xbf"	],
	[ "utf-16be"   => "\xfe\xff"		],
	[ "utf-16le"   => "\xff\xfe"		],
	[ "utf-32be"   => "\x00\x00\xfe\xff"	],
	[ "utf-32le"   => "\xff\xfe\x00\x00"	],
#	[ "utf-1"      => "\xf7\x64\x4c"	],
#	[ "utf-ebcdic" => "\xdd\x73\x66\x73"	],
#	[ "scsu"       => "\x0e\xfe\xff"	],
#	[ "bocu-1"     => "\xfb\xee\x28"	],
#	[ "gb-18030"   => "\x84\x31\x95"	],
	) {
    my ($enc, $bom) = @$_;
    open my $fh, ">", $fnm;
    print $fh $bom;
    print $fh Encode::encode ($enc eq "none" ? "utf-8" : $enc, $str);
    close $fh;

    $csv->column_names (undef);
    open  $fh, "<", $fnm;
    ok (1, "$fnm opened for enc $enc");
    ok ($csv->header ($fh), "headers with BOM for $enc");
    is (($csv->column_names)[1], "b\x{00e5}r", "column name was decoded");
    ok (my $row = $csv->getline_hr ($fh), "getline_hr");
    is ($row->{"b\x{00e5}r"}, "1 \x{20ac} each", "Returned in Unicode");
    unlink $fnm;
    }