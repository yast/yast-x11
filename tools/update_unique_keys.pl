#!/usr/bin/perl
# Martin Vidner <mvidner@suse.cz>
# The unique id's have changed. This script replaces the old ones with
# the new ones.
# It acts as a filter on /var/lib/YaST/unique.inf

open (HWINFO, '/usr/sbin/hwinfo --debug -1 --all |');
while (<HWINFO>)
{
    # Assumption: Old Unique ID follows Unique ID.
    if (/^\s+Unique ID:\s+(\S+)/)
    {
	$new_id = $1;
    }
    elsif (/^\s+Old Unique ID:\s+(\S+)/)
    {
	$map{$1} = $new_id;
    }
}
close (HWINFO);

while (<>)
{
    # A unique key has letters, numbers, plus, underscore and period.
    # Keys that are not mentioned by hwinfo are ignored.
    if (/^([0-9A-Za-z+_.]+)/ && defined($map{$1}))
    {
	$old_id = $1;
	s/^$old_id/$map{$old_id}/;
    }
    print;
}
