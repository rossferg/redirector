#!/usr/bin/env perl

#
#  validate a redirector mappings format CSV file
#
use v5.10;
use strict;
use warnings;

use Test::More;
use Text::CSV;
use Getopt::Long;
use Pod::Usage;
use HTTP::Request;
use LWP::UserAgent;
use URI;

require 'lib/c14n.pl';
require 'lib/lists.pl';

my $skip_canonical;
my $allow_duplicates;
my $query_string;
my $allow_https;
my $disallow_embedded_urls;
my $blacklist = "data/blacklist.txt";
my $whitelist = "data/whitelist.txt";
my $ignore_blacklist;
my $ignore_whitelist;
my $hosts = "";
my %seen = ();
my $help;

GetOptions(
    "blacklist|b=s"  => \$blacklist,
    "ignore-blacklist|B"  => \$ignore_blacklist,
    "skip-canonical|c"  => \$skip_canonical,
    "allow-duplicates|d"  => \$allow_duplicates,
    "query-string|q=s"  => \$query_string,
    "allow-https|t"  => \$allow_https,
    "disallow-embedded-urls|u"  => \$disallow_embedded_urls,
    "hosts|h=s"  => \$hosts,
    "whitelist|w=s"  => \$whitelist,
    "ignore-whitelist|W"  => \$ignore_whitelist,
    'help|?' => \$help,
) or pod2usage(1);

pod2usage(2) if ($help);

my %hosts = load_whitelist($whitelist) unless ($ignore_whitelist);
my %paths = load_blacklist($blacklist) unless ($ignore_blacklist);
my @hosts = split(' ', $hosts);

foreach my $filename (@ARGV) {
    %seen = ();
    check_unquoted($filename);
    test_file($filename);
}

done_testing();

exit;

sub test_file {
    my $filename = shift;
    my $csv = Text::CSV->new({ binary => 1 }) or die "Cannot use CSV: " . Text::CSV->error_diag();

    open(my $fh, "<", $filename) or die "$filename: $!";

    my $names = $csv->getline($fh);
    $csv->column_names(@$names);

    my $line = join(",", @$names);
    ok($line =~ /^Old Url,New Url,Status(,?$|,)/, "incorrect column names [$line]");

    while (my $row = $csv->getline_hr($fh)) {
        test_row("$filename line $.", $row);
    }
}

sub test_row {
    my ($context, $row)  = @_;

    my $old_url = $row->{'Old Url'} // '';
    my $new_url = $row->{'New Url'} // '';
    my $status = $row->{'Status'} // '';

    my $old_uri = check_url($context, 'Old Url', $old_url);

    my $c14n = c14n_url($old_url, $query_string);

    unless ($skip_canonical) {
        is($old_url, $c14n, "Old Url [$old_url] is not canonical [$c14n] $context");
    }

    if ($disallow_embedded_urls) {
        ok($old_url !~ /^http[^\?]*http/, "Old Url [$old_url] contains another Url $context");
    }

    my $scheme = $old_uri->scheme;

    my $s = ($allow_https) ? "s?": "";
    ok($scheme =~ m{^http$s$}, "Old Url [$old_url] scheme [$scheme] must be [http] $context");

    my $old_path = $old_uri->path;
    ok(!$paths{$old_path}, "Old Url [$old_url] path [$old_path] is blacklisted $context");

    if (@hosts) {
        ok(exists {map { $_ => 1 } @hosts}->{$old_uri->host}, "Old Url [$old_url] host not one of [$hosts] $context");
    }

    unless ($allow_duplicates) {
        if ($query_string && defined($old_uri->query)){
            my $query_string = $old_uri->query;
            ok(!defined($seen{$query_string}), "Query string [$query_string] $context is a duplicate of line " . ($seen{$query_string} // ""));
            $seen{$query_string} = $.;
        }
        ok(!defined($seen{$c14n}), "Old Url [$old_url] $context is a duplicate of line " . ($seen{$c14n} // ""));
        $seen{$c14n} = $.;
    }


    if ($status =~ /^301|418$/) {
        my $new_uri = check_url($context, "$status New Url", $new_url);
        if ($new_uri) {
            my $new_host = $new_uri->host;
            ok($hosts{$new_host}, "New Url [$new_url] host [$new_host] not in whitelist $context");
        }
    } elsif ( "410" eq $status) {
        ok($new_url eq '', "unexpected New Url [$new_url] for 410 $context");
    } elsif ( "200" eq $status) {
        ok($new_url eq '', "unexpected New Url [$new_url] for 200 $context");
    } else {
       fail("invalid Status [$status] for Old Url [$old_url] line $.");
    }
}

sub check_url {
    my ($context, $name, $url) = @_;

    # | is valid in our Urls
    $url =~ s/\|/%7C/g;

    ok($url =~ m{^https?://}, "$name [$url] should be a full URI $context");

    my $uri = URI->new($url);
    is($uri, $url, "$name '$url' should be a valid URI $context");

    return $uri;
}

sub check_unquoted {
    my $filename = shift;
    open(FILE, "< $filename") or die "unable to open whitelist $filename";
    my $contents = do { local $/; <FILE> };
    ok($contents !~ /["']/, "file [$filename] contains quotes");
}

__END__

=head1 NAME

validate_mappings - validate a redirector mappings format CSV file

=head1 SYNOPSIS

prove tools/validate_mappings.pl :: [options] [file ...]

Options:

    -b, --blacklist filename        constrain Old Url paths to those not in the given blacklist file
    -B, --ignore-blacklist          ignore the blacklist file
    -c, --skip-canonical            don't check for canonical Old Urls
    -d, --allow-duplicates          allow duplicate Old Urls
    -h, --hosts host                constrain Old Urls to a member of a list of hosts
    -t, --allow-https               allow https in Old Urls
    -q, --query-string p1,p2        significant query-string parameters in Old Urls
                                    '*' allows any parameter, '-' leaves query-string as-is
    -u, --disallow-embedded-urls    disallow Urls in Old Urls
    -w, --whitelist filename        constrain New Urls to those in given whitelist file
    -W, --ignore-whitelist          ignore the whitelist file
    -?, --help                      print usage

=cut
