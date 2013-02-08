#!/usr/bin/env perl

#
#  filter obvious duplicates from CSV
#
use v5.10;
use strict;
use warnings;

my $titles;
my %seen = ();

    while (<STDIN>) {
        chomp;

        unless ($titles) {
            $titles = $_;
            next;
        }

        my ($old, $new, $status) = split(/,/);

        # c14n url
        my $url = $old;
        $url =~ s/\?*$//;
        $url =~ s/\/*$//;
        $url =~ s/\#*$//;

        # line to be printed
        my $line = $_;
        $line =~ s/^[^,]*,//;
        $line = "$url,$line";

        # case-insensitive matchin
        $url = lc($url);

        if ($seen{$url}) {
            if ($new eq $seen{$url}->{new} && $status eq $seen{$url}->{status}) {
                say STDERR "ditching $url line $.";
                next;
            } else {
                if ($status eq $seen{$url}->{status}) {
                    say STDERR "leaving duplicate $url [new url differs] line $.";
                } else {
                    say STDERR "leaving duplicate $url [status differs] line $.";
                }
                say STDERR "> " . $line;
                say STDERR "> " . $seen{$url}->{line};
                say STDERR "";
            }
        }

        $seen{$url} = {
            'new' => $new,
            'status' => $status,
            'line' => $line,
        };
    }

    say $titles;
    foreach my $url (sort keys %seen) {
         say $seen{$url}->{line};
    }

