package TTF::Loca;

=head1 NAME

TTF::Loca - the Locations table, which is intimately tied to the glyf table

=head1 DESCRIPTION

The location table holds the directory of locations of each glyph within the
glyf table. Due to this relationship and the unimportance of the actual locations
when it comes to holding glyphs in memory, reading the location table results
in the creation of glyph objects for each glyph and stores them here.
So if you are looking for glyphs, don't look in the C<glyf> table, look here
instead.

Things get complicated if you try to change the glyph list within the one table.
The recommendation is to create another clean location object to replace this
table in the font, ensuring that the old table is read first and to transfer
or copy glyphs across from the read table to the new table.

=head1 INSTANCE VARIABLES

The instance variables do not start with a space

=over 4

=item glyphs

An array of glyph objects for each glyph.

=item glyphtype

A string containing the class name to create for each new glyph. If empty,
defaults to L<TTF::Glyph>.

=back

=head1 METHODS

=cut

use strict;
use vars qw(@ISA);
@ISA = qw(TTF::Table);

require TTF::Glyph;


=head2 $t->read

Reads the location table creating glyph objects (L<TTF::Glyph>) for each glyph
allowing their later reading.

=cut

sub read
{
    my ($self) = @_;
    my ($fh) = $self->{' INFILE'};
    my ($locFmt) = $self->{' PARENT'}{'head'}->read->{'indexToLocFormat'};
    my ($numGlyphs) = $self->{' PARENT'}{'maxp'}->read->{'numGlyphs'};
    my ($glyfLoc) = $self->{' PARENT'}{'glyf'}{' OFFSET'};
    my ($dat, $last, $i, $loc);

    $self->SUPER::read or return $self;
    read($fh, $dat, $locFmt ? 4 : 2);
    $last = unpack($locFmt ? "N" : "n", $dat);
    for ($i = 0; $i < $numGlyphs; $i++)
    {
        read($fh, $dat, $locFmt ? 4 : 2);
        $loc = unpack($locFmt ? "N" : "n", $dat);
        $self->{'glyphs'}[$i] = ($self->{'glyphtype'} || "TTF::Glyph")->new(
                LOC => $last << ($locFmt ? 0 : 1),
                OUTLOC => $last << ($locFmt ? 0 : 1),
                INFILE => $fh,
                BASE => $glyfLoc,
                OUTLEN => ($loc - $last) << ($locFmt ? 0 : 1),
                LEN => ($loc - $last) << ($locFmt ? 0 : 1)) if ($loc != $last);
        $last = $loc;
    }
    $self;
}


=head2 $t->out($fh)

Writes the location table out to $fh. Notice that not having read the location
table implies that the glyf table has not been read either, so the numbers in
the location table are still valid. Let's hope that C<maxp/numGlyphs> and
C<head/indexToLocFmt> haven't changed otherwise we are in big trouble.

The function uses the OUTLOC location in the glyph calculated when the glyf
table was attempted to be output.

=cut

sub out
{
    my ($self, $fh) = @_;
    my ($locFmt) = $self->{' PARENT'}{'head'}->read->{'indexToLocFormat'};
    my ($numGlyphs) = $self->{' PARENT'}{'maxp'}->read->{'numGlyphs'};
    my ($count, $i, $offset, $g);

    return $self->SUPER::out($fh) unless ($self->{' read'});

    $count = 0;
    for ($i = 0; $i < $numGlyphs; $i++)
    {
        $g = $self->{'glyphs'}[$i];
        if ($g eq "")
        {
            $count++;
            next;
        } else
        {
            if ($locFmt)
            { print $fh pack("N", $g->{'OUTLOC'}) x ($count + 1); }
            else
            { print $fh pack("n", $g->{'OUTLOC'} >> 1) x ($count + 1); }
            $count = 0;
            $offset = $g->{'OUTLOC'} + $g->{'OUTLEN'};
        }
    }
    print $fh pack($locFmt ? "N" : "n", ($locFmt ? $offset: $offset >> 1)) x ($count + 1);
}


=head2 $t->glyphs_do(&func)

Calls func for each glyph in this location table in numerical order:

    &func($glyph, $glyph_num)

=cut

sub glyphs_do
{
    my ($self, $func) = @_;
    my ($i);

    for ($i = 0; $i <= $#{$self->{'glyphs'}}; $i++)
    { &$func($self->{'glyphs'}[$i], $i) if defined $self->{'glyphs'}[$i]; }
    $self;
}

1;

=head1 BUGS

None known

=head1 AUTHOR

Martin Hosken L<Martin_Hosken@sil.org>. See L<TTF::Font> for copyright and
licensing.

=cut

