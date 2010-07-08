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
use IO::Handle;

open ERROR,  '>', "error.txt"  or die $!;
STDERR->fdopen( \*ERROR,  'w' ) or die $!;


require "./include/Simple.pm";
do "./include/functions.plib";

my $configFile = "./include/config.ini";

### NO NEED TO CHANGE ANYTHING BELOW HERE ###

my @countries = ('at', 'au', 'de', 'no', 'pl', 'uk', 'us');
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

my $reloadhack = 0;

for(my $c = 0; $c < @countries; $c++)
{
    my $country         = $countries[$c];

    print "-- Connecting to '$country' Steam Store ... "; # TODO: add timeout!

    my $steamStoreURL   = "http://store.steampowered.com/search/results?sort_by=Name&sort_order=ASC&category1=998&cc=$country&v5=1&page=1";
    my $pageContent     = get($steamStoreURL);

    my @entries         = (cutter($pageContent, "<div class=\"search_pagination_left\">", "</div>") =~ m/^showing\s\d+\s-\s(\d+)\sof\s(\d+)$/);
    my $gamesPerPage    = $entries[0];
    my $totalEntries    = $entries[1];
    my $totalPages      = ceil($totalEntries / $gamesPerPage);

    my %game;

    print "found $totalEntries Game Entries on $totalPages Pages [OK]";

    for (my $page = 1; $page < $totalPages + 1; $page++)
    #for(my $page = 1; $page < 2; $page++)  # use for debugging
    {
        printf("\n\n");
        printf("\x{2554}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2557}\n");
        printf("\x{2551}                                                                                \x{2551} \n");
        printf("\x{2551}   Loading '$country', page %s of %02d                                                  \x{2551} \n", colored(sprintf("%02d", $page), "white", "BOLD"), $totalPages);
        printf("\x{2551}   Entries % 4d - % 4d of %d                                                  \x{2551} \n", (($page - 1) * $gamesPerPage + 1), ($page * $gamesPerPage), $totalEntries);
        printf("\x{2551}                                                                                \x{2551} \n");
        printf("\x{255A}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{2550}\x{255D}\n");
        printf("\n");
        printf("+-----+---------+---------+-------------+----------------------------------------+\n");
        printf("|  #  |  AppID  |  Price  |   Release   |               Game Title               |\n");
        printf("+-----+---------+---------+-------------+----------------------------------------+\n");

        my $gameCount      = ($page - 1) * $gamesPerPage + 1;
        my $tempCursorPos  = 0;

        GETPAGE:

        my $pageContent    = get("http://store.steampowered.com/search/results?sort_by=Name&sort_order=ASC&category1=998&cc=$country&v5=1&page=$page");
        my $tempContent    = cutter($pageContent, '<!-- List Items -->', '<!-- End List Items -->');

        if(!$tempContent =~ m/<!-- List Items -->/)
        {
            $reloadhack++;
            goto GETPAGE;
        }

        for(my $i = $gameCount; $i < ($gameCount + $gamesPerPage); $i++)
        {
            # jump to next game
            $tempContent = substr($tempContent, $tempCursorPos);

            # grab game info
            $game{"appID"}[$i]    = ($tempContent =~ /store\.steampowered\.com\/app\/(\d+)/)[0];
            $game{"price"}[$i]    = formPrice(cutter($tempContent, "<div class=\"col search_price\">", "</div>"));
            $game{"release"}[$i]  = formDate(cutter($tempContent, "<div class=\"col search_released\">", "</div>"), $country);
            $game{"title"}[$i]    = formTitle(cutter($tempContent, "<h4>", "</h4>"));

            # set new cursor position
            $tempCursorPos = index($tempContent, "<div style=\"clear: both;\"></div>") + length("<div style=\"clear: both;\"></div>");

            # print result
            printf("|% 4d |", $i);
            printf("% 8s |", $game{"appID"}[$i]);
            printf("% 8.2f |", $game{"price"}[$i] / 100);
            printf("% 12s |", date("%Y-%b-%d", $game{"release"}[$i]));
            printf(" %s%".(39 - length(substr($game{"title"}[$i], 0, 38)))."s|\n", substr($game{"title"}[$i], 0, 38), " ");

            if($i == $totalEntries)
            {
                goto BREAK;
            }
        }

        BREAK:
        print "+-----+---------+---------+-------------+----------------------------------------+\n";
    }

    # add games to database
    for(my $i = 1; $i < scalar(@{$game{"appID"}}); $i++)
    {
        my $query = qq{
            INSERT INTO sc_steamgames
            (
                `appid`,
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
        my $res = $stmt->execute($game{"appID"}[$i], $game{"title"}[$i], $game{"release"}[$i]);
        $stmt->finish;

        $query = qq|
            INSERT INTO sc_steamgameprices
            (
                `appid`,
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
        $res = $stmt->execute($game{"appID"}[$i], $game{"price"}[$i], $game{"price"}[$i]);
        $stmt->finish;
    }
}

# set new flag for outdated games
my $query = qq|UPDATE sc_steamgames SET flags = 0 WHERE `lastupdate` < (UNIX_TIMESTAMP() - 360*24) |;
my $stmt = $db->prepare($query);
$stmt->execute();

$db->disconnect;

print "Had to reload $reloadhack times.\n";
print "Elapsed time: ".Time::HiRes::tv_interval($start)."seconds\n";

#Todo
#TRUNCATE TABLE `sc_steamgames`
#TRUNCATE TABLE `sc_steamgameprices` 
