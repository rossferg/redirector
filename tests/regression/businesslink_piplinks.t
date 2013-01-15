my $test = Businesslink::Piplinks::Finalised->new();
$test->input_file("dist/businesslink_piplinks_mappings_source.csv");
$test->output_file("dist/businesslink_piplinks_all_tested.csv");
$test->output_error_file("dist/businesslink_piplinks_errors.csv");
$test->output_redirects_file("dist/businesslink_piplinks_redirects_chased.csv");
$test->run_tests();
exit;


package Businesslink::Piplinks::Finalised;
use base 'IntegrationTest';

use v5.10;
use strict;
use warnings;
use Test::More;


sub test {
    my $self = shift;
    
    $self->test_finalised_redirects(@_);
}