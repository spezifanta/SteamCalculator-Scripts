#!/usr/bin/perl -w
#
#   $Id: getGames.pl 3 2010-03-02 16:56:48Z alex@steamcalculator.com $
#
#   SteamCalculator Scripts - http://www.steamcalculator.com
#   Copyright (C) 2010 Alexander Kuhrt (alex@steamcalculator.com)
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

use strict;
use DBI;
use LWP::Simple;
use POSIX qw(ceil strftime);
use Term::ANSIColor;
use Time::HiRes;
binmode(STDOUT, ":utf8");

require "./include/Simple.pm"; 
do "./include/functions.plib";

my $configFile = "./include/config.ini";

### NO NEED TO CHANGE ANYTHING BELOW HERE ### 

my @countries = ('at', 'de', 'uk', 'us');   # if you extend here, make sure to extend your database and 'fromDate' as well
my $start = [Time::HiRes::gettimeofday()];
my $db_host;
my $db_user;
my $db_pass;
my $db_name;

system $^O eq 'MSWin32' ? 'cls' : 'clear';
print "Staring SteamCalculator's 'getgames' Script ...\n\n";

# read config file
if($configFile && -r $configFile)
{
    my $conf = ConfigReader::Simple->new($configFile);
    $conf->parse();

    $db_host = $conf->get("DBHostname");
    $db_user = $conf->get("DBUsername");
    $db_pass = $conf->get("DBPassword");
    $db_name = $conf->get("DBName");
}
else
{
    die("-- Warning: unable to open configuration file '$configFile'\n");
}

print "-- Connecting to MySQL database '$db_name' on '$db_host' as user '$db_user' ... ";

my $db = DBI->connect("DBI:mysql:$db_name:$db_host", $db_user, $db_pass) or die("\nCan't connect to MySQL database '$db_name' on '$db_host'\nServer error: $DBI::errstr\n");

print "connected [OK]\n";

for(my $c = 0; $c < @countries; $c++)
{
    my $country         = $countries[$c];

    print "-- Connecting to '$country' Steam Store ... "; # TODO: add timeout?

    my $steamStoreURL   = "http://store.steampowered.com/search/results?sort_by=Name&sort_order=ASC&category1=996&cc=$country&v5=1&page=1";
    my $pageContent     = get($steamStoreURL);

    my @entries         = (cutter($pageContent, "<div class=\"search_pagination_left\">", "</div>") =~ m/^showing\s\d+\s-\s(\d+)\sof\s(\d+)$/);
    my $gamesPerPage    = $entries[0];
    my $totalEntries    = $entries[1];
    my $totalPages      = ceil($totalEntries / $gamesPerPage);

    my %package;

    print "found $totalEntries Game Entries on $totalPages Pages [OK]";

    for (my $page = 1; $page < $totalPages + 1; $page++)
    #for(my $page = 1; $page < 2; $page++)  # use for debugging
    {
        print "\n\n";
        print "============================================================================================================\n";
        print "||                                                                                                        ||\n";
        print "||  Loading '$country' Page ".colored($page, "white", "BOLD")." of $totalPages                              \n"; 
        print "||                                                                                                        ||\n";
        print "============================================================================================================\n";
        print "|   Entries ".(($page - 1) * $gamesPerPage + 1)." - ".($page * $gamesPerPage)." of $totalEntries            \n";
        print "+-----+---------+---------+-------------+------------------------------------------------------------------+\n";
        print "|  #  |  subID  |  Price  |   Release   |  Title                                                           |\n";
        print "+-----+---------+---------+-------------+------------------------------------------------------------------+\n";

        my $gameCount      = ($page - 1) * $gamesPerPage + 1;
        my $tempCursorPos  = 0;
        my $pageContent    = get("http://store.steampowered.com/search/results?sort_by=Name&sort_order=ASC&category1=996&cc=$country&v5=1&page=$page");
        my $tempContent    = cutter($pageContent, '<!-- List Items -->', '<!-- End List Items -->');

        for(my $i = $gameCount; $i < ($gameCount + $gamesPerPage); $i++)
        {
            # jump to next game
            $tempContent = substr($tempContent, $tempCursorPos);

            # grab game info
            $package{"subID"}[$i]      = cutter($tempContent, "/sub/", "/");
            $package{"price"}[$i]      = formPrice(cutter($tempContent, "<div class=\"col search_price\">", "</div>"));
            $package{"release"}[$i]    = formDate(cutter($tempContent, "<div class=\"col search_released\">", "</div>"), $country); # TODO: replace country code
            $package{"title"}[$i]      = substr(cutter($tempContent, "<div class=\"col search_name\">", "</h4>"), 4);

            # set new cursor position
            $tempCursorPos = index($tempContent, "<div style=\"clear: both;\"></div>") + length("<div style=\"clear: both;\"></div>");

            # print result
            print sprintf("|% 4d |", $i);
            print sprintf("% 8d |", $package{"subID"}[$i]);
            print sprintf("% 8.2f |", $package{"price"}[$i] / 100);
            print sprintf("% 12s |", date("%Y-%b-%d", $package{"release"}[$i]));
            print sprintf("% 12s |", $package{"release"}[$i]);
            print sprintf(" %s%".(65 - length($package{"title"}[$i]))."s|\n", $package{"title"}[$i], " ");

            if($i == $totalEntries)
            {
                goto BREAK;
            }
        }
        
        BREAK:
        print "+-----+---------+---------+-------------+------------------------------------------------------------------+\n";
    }

    # add packages to database
    for(my $i = 1; $i < scalar(@{$package{"subID"}}); $i++)
    {
        my $query = qq{
            INSERT INTO sc_steamboxes
            (
                `subid`,
                `title`,
                `releasedate`,
                `lastupdate`,
                `flags`
            )
            VALUES
            (
                ?,
                ?,
                ?,
                UNIX_TIMESTAMP(),
                1
            )
            ON DUPLICATE KEY UPDATE lastupdate = UNIX_TIMESTAMP(), flags = flags | 1 & ~ 2
        };
        
        my $stmt = $db->prepare($query);
        my $res = $stmt->execute($package{"subID"}[$i], $package{"title"}[$i], $package{"release"}[$i]);
        $stmt->finish;

        $query = qq|
            INSERT INTO sc_steamboxprices
            (
                `subid`,
                $country 
            )
            VALUES
            (
                ?,
                ?
            )
            ON DUPLICATE KEY UPDATE $country = ?
        |;
        
        $stmt = $db->prepare($query);
        $res = $stmt->execute($package{"subID"}[$i], $package{"price"}[$i], $package{"price"}[$i]);
        $stmt->finish;
    }
}

$db->disconnect;

print "Elapsed time: ".Time::HiRes::tv_interval($start)."seconds\n";
