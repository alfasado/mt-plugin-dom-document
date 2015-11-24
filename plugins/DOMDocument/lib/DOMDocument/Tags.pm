package DOMDocument::Tags;
use strict;
use warnings;

sub _hdlr_set_attribute {
    my ( $ctx, $args, $cond ) = @_;
    my $node = $args->{ node };
    if (! $node ) {
        my $template = $args->{ tmpl } || $args->{ template };
        my $tag = $args->{ tag } || return '';
        my $index = undef;
        if ( $tag && ( ref $tag eq 'ARRAY' ) ) {
            $index = @$tag[ 1 ];
            $tag = @$tag[ 0 ];
        }
        my $tmpl = $ctx->stash( 'template' );
        if ( $template ) {
            $tmpl = $ctx->{ __stash }{ vars }{ $template };
            if (! $tmpl ) {
                $tmpl = $ctx->{ __stash }{ vars }{ lc( $template ) };
            }
        }
        my $elements = $tmpl->getElementsByTagName( $tag );
        if (! $elements ) {
            return '';
        }
        if (! defined( $index ) ) {
            $index = $args->{ index } || 0;
        }
        $node = @$elements[ $index ];
    } else {
        $node = $ctx->{ __stash }{ vars }{ $node };
        if (! $node ) {
            $node = $ctx->{ __stash }{ vars }{ lc( $node ) };
        }
    }
    if (! $node ) {
        return '';
    }
    if ( ( ref $node ) ne 'MT::Template::Node' ) {
        return '';
    }
    my $attributes = $args->{ attributes } || $args->{ attr } || $args->{ attrs };
    return '' unless $attributes;
    if ( ref( $attributes ) eq 'HASH' ) {
        while ( my ( $key, $value ) = each %$attributes ) {
            $node->setAttribute( $key, $value );
        }
    } elsif ( ref( $attributes ) eq 'ARRAY' ) {
        my $is_key = 1;
        my $key;
        for my $attr ( @$attributes ) {
            if ( $is_key == 1 ) {
                $is_key = 0;
                $key = $attr;
            } else {
                $is_key = 1;
                $node->setAttribute( $key, $attr );
            }
        }
    }
    return '';
}

sub _hdlr_set_raw_template {
    my ( $ctx, $args, $cond ) = @_;
    my $name = $args->{ name } || return '';
    my $uncompiled = $ctx->stash( 'uncompiled' ) || '';
    $ctx->{ __stash }{ vars }{ $name } = $uncompiled;
    $ctx->{ __stash }{ vars }{ lc( $name ) } = $uncompiled;
    return '';
}

sub _hdlr_create_element {
    my ( $ctx, $args, $cond ) = @_;
    my $tag = $args->{ name } || $args->{ tag_name }
        || $args->{ tag } || $args->{ tagname };
    if (! $tag ) {
        return '';
    }
    my $attributes = $args->{ attributes } || $args->{ attr } || $args->{ attrs };
    if ( ref( $attributes ) eq 'ARRAY' ) {
        my $_attributes;
        my $is_key = 1;
        my $key;
        for my $attr ( @$attributes ) {
            if ( $is_key == 1 ) {
                $is_key = 0;
                $key = $attr;
            } else {
                $is_key = 1;
                $_attributes->{ $key } = $attr;
            }
        }
        $attributes = $_attributes;
    }
    require MT::Template::Node;
    my $node = MT::Template::Node->new( tag => $tag,
        attributes => $attributes, template => $ctx->stash( 'template' ) );
    if ( my $name = $args->{ name } ) {
        $ctx->{ __stash }{ vars }{ $name } = $node;
        $ctx->{ __stash }{ vars }{ lc( $name ) } = $node;
    } elsif ( $args->{ setvar } ) {
        return $node;
    }
    return '';
}

sub _hdlr_create_text_node {
    my ( $ctx, $args, $cond ) = @_;
    my $text = $args->{ text } || return '';
    require MT::Template::Node;
    my $node = MT::Template::Node->new( tag => 'TEXT',
              nodeValue => $text, template => $ctx->stash( 'template' ) );
    if ( my $name = $args->{ name } ) {
        $ctx->{ __stash }{ vars }{ $name } = $node;
        $ctx->{ __stash }{ vars }{ lc( $name ) } = $node;
    } elsif ( $args->{ setvar } ) {
        return $node;
    }
    return '';
}

sub _hdlr_build_node {
    my ( $ctx, $args, $cond ) = @_;
    my $node = $args->{ node } || return '';
    my $element = $ctx->{ __stash }{ vars }{ $node };
    my $builder = $ctx->stash( 'builder' );
    my $tokens = $builder->compile( $ctx, '<mt:Unless></mt:Unless>' )
        or die $builder->errstr;
    return '' unless defined( $tokens );
    my $data = bless $tokens, 'MT::Template::Tokens';
    my $tag = $data->getElementsByTagName( 'Unless' );
    @$tag[ 0 ]->appendChild( $element );
    require MT::App;
    my $token = MT::App::make_magic_token();
    $ctx->var( $token, $data );
    $args->{ name } = $token;
    return MT::Template::Tags::Core::_hdlr_get_var( $ctx, $args, $cond );
}

sub hdlr_get_element_by_id {
    my ( $ctx, $args, $cond ) = @_;
    my $tmpl = $args->{ tmpl } || $args->{ template };
    my $id = $args->{ id };
    return '' unless $id;
    if (! $tmpl ) {
        $tmpl = $ctx->stash( 'template' );
        if ( $args->{ setvar } ) {
            return $tmpl->getElementById( $id );
        }
        return '';
    }
    my $tokens = $ctx->{ __stash }{ vars }{ $tmpl };
    if (! $tokens ) {
        $tokens = $ctx->{ __stash }{ vars }{ lc( $tmpl ) };
    }
    if (! $tokens ) {
        return '';
    }
    my @_t;
    my $all_tokens = __get_all_nodes( $tokens, @_t );
    for my $t ( @$all_tokens ) {
        if ( my $a = $t->attributes ) {
            if ( $a->{ id } && $a->{ id } eq $id ) {
                if ( $args->{ setvar } ) {
                    return $t;
                }
                last;
            }
        }
    }
    return '';
}

sub _hdlr_get_elements_by {
    my ( $ctx, $args, $cond ) = @_;
    my $template = $args->{ tmpl } || $args->{ template };
    my $name = $args->{ name } || $args->{ tag_name }
        || $args->{ tag } || $args->{ tagname };
    if (! $name ) {
        return '';
    }
    my $index = undef;
    if ( $name && ( ref $name eq 'ARRAY' ) ) {
        $index = @$name[ 1 ];
        $name = @$name[ 0 ];
    }
    if (! defined( $index ) ) {
        $index = $args->{ index } || 0;
    }
    my $tmpl = $ctx->stash( 'template' );
    if ( $template ) {
        $tmpl = $ctx->{ __stash }{ vars }{ $template };
        if (! $tmpl ) {
            $tmpl = $ctx->{ __stash }{ vars }{ lc( $template ) };
        }
    }
    my $elements;
    my $tag = lc( $ctx->stash( 'tag' ) );
    if ( $tag eq 'getelementsbyname' ) {
        $elements = $tmpl->getElementsByName( $name );
    } elsif ( $tag eq 'getelementsbytagname' ) {
        $elements = $tmpl->getElementsByTagName( $name );
    } elsif ( $tag eq 'getelementsbyclassname' ) {
        if (! $template ) {
            $elements = $tmpl->getElementsByClassName( $name );
        } else {
            my @_t;
            my $all_tokens = __get_all_nodes( $tmpl, @_t );
            for my $t ( @$all_tokens ) {
                if ( my $a = $t->attributes ) {
                    if ( $a->{ class } && $a->{ class } eq $name ) {
                        push ( @$elements, $t );
                    }
                }
            }
        }
    }
    if (! $elements ) {
        return '';
    }
    if ( $args->{ setvar } || $args->{ force } ) {
        my $tmpl = @$elements[ $index ]->ownerDocument;
        if ( defined( $index ) ) {
            return @$elements[ $index ];
        } else {
            return $elements;
        }
    }
    return '';
}

sub _hdlr_node_value {
    my ( $ctx, $args, $cond ) = @_;
    my $node = $args->{ node } || return '';
    $node = $ctx->{ __stash }{ vars }{ $node };
    if (! $node ) {
        $node = $ctx->{ __stash }{ vars }{ lc( $node ) };
    }
    if ( ( ref $node ) ne 'MT::Template::Node' ) {
        return '';
    }
    if ( $node ) {
        return $node->nodeValue;
    }
    return '';
}

sub _hdlr_append_child {
    my ( $ctx, $args, $cond ) = @_;
    my $node = $args->{ node } || return '';
    my ( $pointer , $append );
    if ( ( ref $node ) eq 'ARRAY' ) {
        $pointer = @$node[ 0 ];
        $append = @$node[ 1 ];
        if ( (! $pointer ) || (! $append ) ) {
            return '';
        }
        $pointer = $ctx->{ __stash }{ vars }{ $pointer };
        if (! $pointer ) {
            $pointer = $ctx->{ __stash }{ vars }{ lc( $pointer ) };
        }
        $append = $ctx->{ __stash }{ vars }{ $append };
        if (! $append ) {
            $append = $ctx->{ __stash }{ vars }{ lc( $append ) };
        }
        if ( (! $pointer ) || (! $append ) ) {
            return;
        }
    } else {
        my $template = $args->{ tmpl } || $args->{ template };
        my $tmpl = $ctx->stash( 'template' );
        if ( $template ) {
            $tmpl = $ctx->{ __stash }{ vars }{ $template };
            if (! $tmpl ) {
                $tmpl = $ctx->{ __stash }{ vars }{ lc( $template ) };
            }
        }
        my $tag = $args->{ tag } || $args->{ tag_name };
        my $name = $args->{ name };
        my $classname = $args->{ classname } || $args->{ class_name };
        if ( (! $tag ) && (! $name ) && (! $classname ) ) {
            my $tmpl = $ctx->stash( 'template' );
            my $append = $ctx->{ __stash }{ vars }{ $node };
            if (! $append ) {
                $append = $ctx->{ __stash }{ vars }{ lc( $node ) };
            }
            $tmpl->appendChild( $append );
            return '';
        }
        my $index = undef;
        if ( $tag && ( ref $tag eq 'ARRAY' ) ) {
            $index = @$tag[ 1 ];
            $tag = @$tag[ 0 ];
        }
        my $elements;
        if ( $tag ) {
            $elements = $tmpl->getElementsByTagName( $tag );
        } elsif ( $classname ) {
            $ctx->stash( 'tag', 'GetElementsByClassName' );
            $args->{ name } = $name;
            $args->{ force } = 1;
            $args->{ index } = undef;
            $elements = _hdlr_get_elements_by( $ctx, $args, $cond );
        } else {
            $elements = $tmpl->getElementsByName( $name );
        }
        if (! $elements ) {
            return '';
        }
        $append = $ctx->{ __stash }{ vars }{ $node };
        if (! $append ) {
            $append = $ctx->{ __stash }{ vars }{ lc( $node ) };
        }
        if (! $append ) {
            return '';
        }
        if (! defined( $index ) ) {
            $index = $args->{ index } || 0;
        }
        $pointer = @$elements[ $index ];
    }
    if ( (! $pointer ) || (! $append ) ) {
        return '';
    }
    if ( ( ref $pointer ) ne 'MT::Template::Node' ) {
        return '';
    }
    my $tmpl = $pointer->ownerDocument;
    if ( $args->{ insert_before } ) {
        $tmpl->insertBefore( $append, $pointer );
    } elsif ( $args->{ insert_after } ) {
        $tmpl->insertAfter( $append, $pointer );
    } else {
        $pointer->appendChild( $append );
    }
    return '';
}

sub _hdlr_insert_before {
    my ( $ctx, $args, $cond ) = @_;
    $args->{ insert_before } = 1;
    return _hdlr_append_child( $ctx, $args, $cond );
}

sub _hdlr_insert_after {
    my ( $ctx, $args, $cond ) = @_;
    $args->{ insert_after } = 1;
    return _hdlr_append_child( $ctx, $args, $cond );
}

sub _hdlr_remove_attribute {
    my ( $ctx, $args, $cond ) = @_;
    my $node = $args->{ node } || return '';
    my $element = $ctx->{ __stash }{ vars }{ $node };
    if (! $element ) {
        $element = $ctx->{ __stash }{ vars }{ lc( $node ) };
    }
    if (! $element ) {
        return '';
    }
    if ( ( ref $element ) ne 'MT::Template::Node' ) {
        return '';
    }
    my $name = $args->{ name };
    if (! $name ) {
        $element->[ 1 ] = {};
    } else {
        # my %attributes = $element->[ 1 ]; # warnings
        my $_attributes = $element->[ 1 ];
        my %attributes = %$_attributes;
        delete( $attributes{ $name } );
        $element->[ 1 ] = \%attributes;
    }
    return '';
}

sub _hdlr_set_inner_html {
    my ( $ctx, $args, $cond ) = @_;
    my $node = $args->{ node } || return '';
    my $element = $ctx->{ __stash }{ vars }{ $node };
    if (! $element ) {
        $element = $ctx->{ __stash }{ vars }{ lc( $node ) };
    }
    if (! $element ) {
        return '';
    }
    if ( ( ref $element ) ne 'MT::Template::Node' ) {
        return '';
    }
    my $uncompiled = $ctx->stash( 'uncompiled' ) || '';
    $element->innerHTML( $uncompiled );
    return '';
}

sub _hdlr_get_inner_html {
    my ( $ctx, $args, $cond ) = @_;
    my $node = $args->{ node } || return '';
    my $element = $ctx->{ __stash }{ vars }{ $node };
    if (! $element ) {
        $element = $ctx->{ __stash }{ vars }{ lc( $node ) };
    }
    if (! $element ) {
        return '';
    }
    if ( ( ref $element ) ne 'MT::Template::Node' ) {
        return '';
    }
    return $element->innerHTML();
}

sub __get_all_nodes {
    my ( $tokens, $nodes ) = @_;
    for my $t ( @$tokens ) {
        push( @$nodes, $t );
        if ( my $children = $t->childNodes ) {
            __get_all_nodes( $children, $nodes );
        }
    }
    return $nodes;
}

1;