use strict;
use Test::More;
use Pandoc::Walker;
use Pandoc::Elements qw(Str Space from_json);

sub load {
    local (@ARGV, $/) = ('t/documents/example.json'); 
    from_json(<>);
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

$links = [ ];
walk $doc, sub {
    return unless ($_[0]->name eq 'Link' or $_[0]->name eq 'Image');
    push @$links, $_[0]->target->[0];
};

is_deeply $links, $LINKS, 'walk';

transform $doc, sub {
    return ($_[0]->name eq 'Link' ? [] : ());
};

is_deeply query($doc,\&urls), ['image.png'], 'transform, remove elements';

$doc = load();
transform $doc, sub {
    my ($e) = @_;
    return unless $e->name eq 'Link';
    my $a = [ Str "<", @{$e->content}, Str ">" ];
    return $a;
};

my $header = $doc->content->[0]->content;
is_deeply $header, [ 
    Str 'Example', Space, Str '<', Str 'http://example.org/', Str '>'
], 'transform, multiple elements';

done_testing;
