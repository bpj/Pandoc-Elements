use strict;
use Test::More;
use Pandoc::Walker;
use Pandoc::Elements qw(Str Space pandoc_json);

sub load {
    local (@ARGV, $/) = ('t/documents/example.json'); 
    pandoc_json(<>);
}

my $doc = load();

my $LINKS = [qw(
    http://example.org/
    image.png
    http://example.com/
)];

sub urls {
    return unless ($_[0]->name eq 'Link' or $_[0]->name eq 'Image');
    return $_[0]->target->[0];
};

my $links = query $doc, \&urls;
is_deeply $links, $LINKS, 'query';
is_deeply $doc->query(\&urls), $LINKS, '->query';

sub links {
    return unless ($_[0]->name eq 'Link' or $_[0]->name eq 'Image');
    push @$links, $_[0]->url;
}

$links = [ ];
walk $doc, \&links;
is_deeply $links, $LINKS, 'walk';

$links = [ ];
$doc->walk(\&links);
is_deeply $links, $LINKS, '->walk';

transform $doc, sub {
    return ($_[0]->name eq 'Link' ? [] : ());
};

is_deeply query($doc,\&urls), ['image.png'], 'transform, remove elements';

sub escape_links {
    my ($e) = @_;
    return unless $e->name eq 'Link';
    my $a = [ Str "<", @{$e->content}, Str ">" ];
    return $a;
}

$doc = load();
transform $doc, \&escape_links;
is scalar @{ query($doc, \&urls) }, 1, 'transform, escaped links';

$doc = load();
$doc->transform(\&escape_links);
is scalar @{ query($doc, \&urls) }, 1, '->transform, escaped links';

my $header = $doc->content->[0]->content;
is_deeply $header, [ 
    Str 'Example', Space, Str '<', Str 'http://example.org/', Str '>', Str '!'
], 'transform, multiple elements';

$doc = load();
transform $doc, sub {
    my $e = shift;
    return unless $e->name eq 'Header';
    $e->transform(\&escape_links);
};

is scalar @{ query($doc, \&urls) }, 2, 'nested transformation';

#SKIP: {
#    $header = $doc->content->[0];
#    $header->transform(sub {
#        return unless $_[0]->name eq 'Header';
#        return Para $_[0]->[0]->content;
#    });
#}

done_testing;
