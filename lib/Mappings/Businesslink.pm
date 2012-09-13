package Mappings::Businesslink;

use strict;
use warnings;
use base 'Mappings::Rules';



sub actual_nginx_config {
    my $self = shift;
    
    my $config_or_error_type;
    my $config_line;
    my $mapping_status = '';
    
    if ( defined $self->{'old_url_parts'}{'query'} ) {

        if ( '/bdotg/action/home' eq $self->{'old_url_parts'}{'path'} ) {
            $config_or_error_type = 'location'; 
            $config_line = "location = $self->{'old_url_parts'}{'path'} { return 301 $self->{'new_url'}; }\n"; 
            # do we want this instead of old url relative?
        }
        else {
            my $map_key = $self->get_map_key( $self->{'old_url_parts'} );
            
            if ( defined $self->{'whole_tag'} ) {
                $mapping_status = lc $self->{'whole_tag'};
            }

            if ( defined $map_key ) {
                if ( '410' eq $self->{'status'} ) {
                    # 410 Gone
                    $config_or_error_type   = 'gone_map';
                    $config_line = "~${map_key} 410;\n";
                }
                elsif ( '301' eq $self->{'status'} ) {
                    if ( 'awaiting-content' eq $mapping_status || 'awaiting-publication' eq $mapping_status ) {
                        # 418 I'm a Teapot -- used to signify "page will exist soon"
                        $config_or_error_type   = 'awaiting_content_map';
                        $config_line = "~${map_key} 418;\n";
                    }
                    elsif ( length $self->{'new_url'}) {
                        # 301 Moved Permanently
                        $config_or_error_type   = 'redirect_map';
                        $config_line = "~${map_key} $self->{'new_url'};\n";
                    } 
                    else {
                        $config_or_error_type = 'no_destination_error';
                        $config_line = "$self->{'old_url'}\n";
                    }
                }
            }
            else {
                $config_or_error_type = 'no_map_key_error'; 
                $config_line = "$self->{'old_url'}\n"; 
            }
        }
        return( $self->{'old_url_parts'}{'host'}, $config_or_error_type, $config_line );    
    }
    # if no query string, we treat it as a furl
    else {
        return $self->location_config();
    }    
    
}
sub get_map_key {
    my $self         = shift;
    my $parts        = shift;
    
    my $path         = $parts->{'path'};
    my $query_string = $parts->{'query'};
    
    my $key;
    my $topic;
    my $item;
    
    if ( defined $query_string ) {
        $topic = $1
            if $query_string =~ m{topicId=(\d+)};
        $item = $1
            if $query_string =~ m{itemId=(\d+)};
    }
    
    if ( defined $topic && defined $item ) {
        if ( $path =~ m{^/bdotg/action/layer} ) {
            $key = "topicId=$topic";
        }
        else {
           $key = "itemId=$item";
        }
    }
    elsif ( defined $topic ) {
        $key = "topicId=$topic";
    }
    elsif ( defined $item ) {
        $key = "itemId=$item";
    }
    
    return $key; 
}

1;