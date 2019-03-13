#!/usr/bin/perl

use 5.018;
use strict;
use warnings;

my $proj = shift @ARGV; # cube eac mv
my $channel = shift @ARGV; # psnr_avg All size ts
my @dirs = (@ARGV); # directories

my @logs;

for my $dir (@dirs){
    @logs = (@logs, map { chomp $_; "$dir/$_"; } grep(/$proj/, `ls $dir`));
}

my @values;
for my $log (@logs) {
    my @vs = &extract_all($log, $channel);
    # say "get @vs from $metric/$log, $channel";
    @values = (@values, @vs);
}

@values = sort { $a <=> $b } @values;
for(my $i = 0; $i < @values; $i++){
    # my $ratio = ($i+1) * 1.0 / @values;
    # if ($ratio > 0.22 and $ratio < 0.28){
    #     say (join ",", $ratio, $values[$i]);
    # }elsif($ratio > 0.47 and $ratio < 0.53){
    #     say (join ",", $ratio, $values[$i]);
    # }elsif($ratio > 0.72 and $ratio < 0.78){
    #     say (join ",", $ratio, $values[$i]);
    # }

    say (join ",", (($i+1) * 1.0 / @values, $values[$i]));
}

# say "avg: " . &avg(@values);

sub extract_all {
    my ($file, $t) = (@_);
    my @values;
    my $lnr = 0;

    if($t =~ /size/){
        my $base = $file;
        $base =~ s/${proj}/cube/g;
        push @values, ((-s $file) / (-s $base));
    }elsif($t =~ /ts/){
        my ($fr_nr, $min, $sec, $ms);
        open my $fh, "<", $file or die $!;
        while(<$fh>){
            chomp;
            $fr_nr = $1 if /(\d+) fps/;
            ($min, $sec) = ($1, $2) if /real\s+([^m]+)m([^s]+)s/;
        }
        close $fh;
        $ms = ($min * 60 + $sec) * 1000;
        push @values, ($ms / $fr_nr);
    }else{
        open my $fh, "<", $file or die $!;
        while(<$fh>){
            $lnr++;
            if(/$t:([^\s]+)/){
                next if $lnr == 1;
                my $v = $1;
                $v = 1000 if $v =~ /(inf|Inf|INF)/;
                push @values, $v;
            }
        }
        close $fh;
    }
    return @values;
}


use List::Util qw/sum/;

sub avg {
    return (sum @_) / @_;
}

sub std {
    my $avg = &avg(@_);
    my @stds = map { ($_ - $avg) ** 2 } @_;
    return sqrt(&avg(@stds));
}
