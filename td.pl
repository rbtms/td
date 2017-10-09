#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Cwd qw{ abs_path };
use File::Basename qw{ dirname };


our $_ENV        = '';
our $_PATH       = '';
our $_DIR        = '';
our $_VERSION    = '';

##
# TODO: Make folder on install
##
our $_TABLE_PATH = $ENV{'HOME'}.'/.td/project_table.txt';

##
# TODO: Add or die to file pipes
# TODO: Add priorities ?
# TODO: Add command to fix project_table non-existing entries
# TODO: Doesn't accept folder names with spaces
##

##
# stty is part of the coreutils package ####
##
our($_LINES, $_COLS) = `stty size` =~ /(\d+) (\d+)/;

$| = -1;


sub current_path       { return dirname( abs_path($0) ); }
sub current_dir        { return ( split( /\\/, current_path() ) )[-1] }
sub current_dir_cygwin { return ( split(/\//, $_[0]) )[-1];           }

##
# TODO: Get cygwin path
##
sub win_path
    {
        my($path) = @_;
        
        $path = substr($path, 1);
        $path =~ s/\\/\//;
        
        return 'C:/cygwin64/'.$path;
    }

sub date
    {
        my($s, $min, $h, $d, $m, $y) = localtime(time());
        
        for($s, $min, $h, $d, $m) { $_ = "0$_" if length $_ == 1; }
        
        $m++;
        $y += 1900;
        
        return "$d/$m/$y $h:$min:$s";
    }

sub get_table
    {
        open(TABLE, '<', $_TABLE_PATH);
            my @table = <TABLE>;
            my $len   = scalar @table;
            
            chomp @table;
        close(TABLE);
        
        return @table;
    }

sub add_to_table
    {
        my($path, $name) = @_;
        
        
        my @table = get_table();
            
        push(@table, "$path $name");
        
        open(TABLE, '>', $_TABLE_PATH);
            print TABLE join("\n", @table);
        close(TABLE);
    }

sub remove_from_table
    {
        my($curr_path, $curr_dir) = @_;
        my $path;
        
        
        my @table = get_table();
        my $len   = scalar @table;
        
        return undef if $len == 0;
        
        
        for(my $i = 0; $i < $len; $i++)
            {
                $path = ( split(' ', $table[$i]) )[0];
                
                ##
                # Remove entry if there is a match
                ##
                if($path eq $curr_path)
                    {
                        splice(@table, $i, 1);
                        
                        open(TABLE, '>', './project_table.txt');
                            print TABLE join( "\n", @table, );
                        close(TABLE);
                        
                        return 1;
                    }
            }
        
        
        return undef;
    }

sub get_data
    {
        my($attr) = @_;

        open(DATA, '<', "./.td/data.txt");
            for my $line (<DATA>)
                {
                    if( $line =~ /$attr=(.+)\n/ )
                        {
                            close(DATA);
                            
                            return $1;
                        }
                }
        close(DATA);
        
        return undef;
    }

sub set_data
    {
        my($attr, $val) = @_;
        
        open(DATA, '<', "./.td/data.txt");
            my @data = <DATA>;
            my $len  = scalar @data;
            
            chomp @data;
        close(DATA);
        
        die if $len == 0; ####
        
        
        for my $i (0...$len)
            {
                if( $data[$i] =~ /$attr=/ )
                    {
                        $data[$i] = "$attr=$val";
                        
                        open(DATA, '>', "./.td/data.txt");
                            print DATA join("\n", @data);
                        close(DATA);
                        
                        return 1;
                    }
            }
        
        return undef;
    }

sub get_entry_attr
    {
        my($line) = @_;
        my($n, $tag, $status, $version, $date, $entry) = $line =~ /n=(\d+) t=(.+?) s=(.+?) v=(.+?) d=(.+?) e=(.+)/;
        
        return ($n, $tag, $status, $version, $date, $entry);
    }

sub set_entry_attr
    {
        my($n, $attr, $val) = @_;
        my $found = undef;
        my %attr = ();
        
        open(TODO, '<', "./.td/todo.txt");
            my @todo = <TODO>;
            chomp @todo;
        close(TODO);
        
        
        for my $i (0...scalar @todo)
            {
                if( ( split(' ', $todo[$i]) )[0] eq "n=$n" )
                    {
                        @attr{'n', 't', 's', 'v', 'd', 'e'} = get_entry_attr($todo[$i]);
                        $attr{$attr} = $val;
                        
                        $todo[$i] = "n=".$attr{'n'}." t=".$attr{'t'}." s=".$attr{'s'}." v=".$attr{'v'}." "
                                  . "d=".$attr{'d'}." e=".$attr{'e'};
                        
                        $found = 1;
                        last;
                    }
            }
        
        
        open(TODO, '>', "./.td/todo.txt");
            print TODO "$_\n" foreach @todo;
        close(TODO);
        
        
        return $found;
    }

sub add_entry
    {
        my($tag, $entry) = @_;
        
        my $dir = $_DIR;
        
        my $n       = get_data('n')+1;
        my $date    = date();
        my $status  = 'yet';
        my $version = get_data('version');
        
        
        open(TODO, '>>', "./.td/todo.txt");
            print TODO "n=$n t=$tag s=$status v=$version d=$date e=$entry\n";
        close(TODO);
        
        
        set_data('n', $n);
    }

sub remove_entry
    {
        my($n) = @_;
        
        open(TODO, '<', "./.td/todo.txt");
            my @todo = <TODO>;
            my $len  = scalar @todo;
            
            chomp @todo;
        close(TODO);
        
        return undef if $len == 0;
        
        
        for(my $i = 0; $i < $len; $i++)
            {
                if( ( split(' ', $todo[$i]) )[0] eq "n=$n" )
                    {
                        splice(@todo, $i, 1);
                        
                        open(TODO, '>', "./.td/todo.txt");
                            print TODO "$_\n" foreach @todo;
                        close(TODO);
                        
                        return 1;
                    }
            }
        
        return undef;
    }

sub print_entries
    {
        ##
        # So that it doesn't throw a warning on a hash of array of hashes
        ##
        no warnings "experimental::autoderef";
        
        if( !-e "./.td/todo.txt")
            {
                print "td: There is not a td project in this folder. Have a look at td help.\n";
                print "\nMaybe you meant td init?\n\n";
                
                return undef;
            }
        
        
        my($hashref, $path) = @_;
        my %filter = %{$hashref};
        
        $path ||= '.';
        
        my %entry    = ();
        my %tags     = ();
        my %attr_len = ( n => 0, s => 0, v => 0, d => 0, e => 0 );
        
        
        open(TODO, '<', $path."/.td/todo.txt");
            my @todo = <TODO>;
            chomp @todo;
        close(TODO);
        
        
        ##
        # Get entries
        ##
        ENTRY:
        for(my $i = 0; $i < scalar @todo; $i++)
            {
                my($n, $tag, $status, $version, $date, $entry) = get_entry_attr( $todo[$i] );
                
                
                %entry = ( n => $n, s => $status, v => $version, d => $date, e => $entry );
                
                for my $key (keys %filter)
                    {
                        if($key =~ /e|entry/)
                            {
                                my $entry = $filter{$key};
                                next ENTRY if $entry{$key} !~ /$entry/;
                            }
                        elsif($key =~ /t|tag/)
                            {
                                next ENTRY if $filter{$key} ne $tag;
                            }
                        elsif( defined $entry{$key} and $entry{$key} ne $filter{$key} )
                            {
                                next ENTRY;
                            }
                    }
                
                
                $attr_len{'n'} = length($n)       if length($n)       > $attr_len{'n'};
                $attr_len{'v'} = length($version) if length($version) > $attr_len{'v'};
                $attr_len{'d'} = length($date)    if length($date)    > $attr_len{'d'}; ####
                $attr_len{'e'} = length($entry)   if length($entry)   > $attr_len{'e'};
                
                
                # Initialize tag
                $tags{$tag} ||= [];
                
                push( @{$tags{$tag}}, {%entry});
            }
        
        
        # tag hash
        #   -> entries array
        #       -> entry hash
        for my $tag (sort keys %tags)
            {
                print "\n\n";
                print "   $tag\n";
                print " --------\n\n";
                
                for my $tag_arr ( $tags{$tag} )
                    {
                        my @tag_arr = @{$tag_arr};
                        
                        for my $entry ( @tag_arr )
                            {
                                %entry = %{$entry};
                                
                                #$entry{'d'} =~ s/T/ /;
                                #$entry{'d'} =~ s/-/\//g;
                                $entry{'n'} = " [" . ( ' ' x ( $attr_len{'n'}-length( $entry{'n'} ) + 1 ) ) . $entry{'n'}." ]";
                                
                                $entry{'e'} .= ' ' x ( $attr_len{'e'} - length($entry{'e'}) );
                                
                                
                                my $line = $entry{'n'}."  ".$entry{'e'};
                                
                                $line .= ' ' x ($_COLS - length($line) - length( 'v'.$entry{'v'}." at ".$entry{'d'}) - 4);
                                $line .= 'v'.$entry{'v'}." at ".$entry{'d'};
                                
                                print $line, "\n";
                            }
                    }
            }
        
        print "\n";
    }

sub init_files
    {
        my($name, $version) = @_;
    
        my $n    = 0;
        my $date = date();
        
        if(!-e './.td')
            {
                print 'td: There is no projects folder.';
                return;
            }
        
        open(DATA, '>', "./.td/data.txt");
            print DATA "name=$name\n", "n=$n\n", "version=$version\n", "init_date=$date";
        close(DATA);
        
        open(TODO, '>', "./.td/todo.txt");
        close(TODO);
    }

##
# TODO: Add description option?
##
sub init
    {
        my @args = @_;
        my($name, $version);
        
        
        ##
        # Get initial values
        ##
        my $init_version = '0.1.0';
        
        
        ##
        # Initialize td with user input
        ##
        print "Project name($_DIR): ";
        $name = <STDIN>;
        
        print "Initial version($init_version): ";
        $version = <STDIN>;
        
        
        ##
        # Set to default values if user pressed enter
        ##
        $name eq "\n"
            ? $name = $_DIR
            : chomp $name;
        $version eq "\n"
            ? $version = $init_version
            : chomp $version;
        
        
        ##
        # Add to project table and create folder
        # TODO: Under current implementation, there can only be one project with one name
        ##
        if( -e "./.td" )
            {
                print "td: Cannot create project $name - It already exists.\n";
            }
        else
            {
                add_to_table($_PATH, $name);
                    
                mkdir "./.td";
                init_files($name, $version);
                
                print "td: Project $name initializated.\n";
            }
    }

sub _close
    {
        if(!-e './.td')
            {
                print "td: There isn't a td project in this folder.\n";
                return;
            }
    
    
        ##
        # Ask the user for confirmation before closing
        ##
        print 'Confirm(N): ';
        
        my $yn = <STDIN>;
        chomp $yn;
        
        if($yn !~ /^[yY]$/) { print "\ntd: Operation cancelled.\n"; return; }
        
        
        ##
        # If there has been a match, remove project folder
        ##
        my $success = remove_from_table($_PATH); ####
        
        if($success)
            {
                my $name = get_data('name');
            
                system("rm -rf ./.td");
                
                print "\ntd: Project $name closed.\n";
            }
        else
            {
                print "td: Couldn't close project.\n";
            }
    }

sub add
    {
        my($entry, $tag) = split(' -t ', join(' ', @_));
        
        com_help('add') if not defined $entry;
        
        
        add_entry
            (
                $tag    || 'TODO',
                $entry
            );
        
       print_entries({ s => 'yet' });
    }

sub rm
    {
        my($n) = @_;
        
        
        my $success = remove_entry($n);
        
        if($success) { print_entries({ s => 'yet' }); }
        else         { print "td: There is no such entry with that number.\n"; }
    }

sub done
    {
        my($n) = @_;
        
        if(not defined $n) { print_entries({ s => 'done' });  }
        else               { set_entry_attr($n, 's', 'done'); }
    }

##
# TODO: Only accepts one argument
##
sub filter
    {
        my @args = @_;
        
        my $attr = ($args[0] eq 'version' or $args[0] eq 'v') ? 'v' :
                   ($args[0] eq 'number'  or $args[0] eq 'n') ? 'n' :
                   ($args[0] eq 'tag'     or $args[0] eq 't') ? 't' :
                   ($args[0] eq 'status'  or $args[0] eq 's') ? 's' :
                                                                'e';
        
        if($attr eq 'e') { print_entries({ 'e'   => $args[0] }); }
        else             { print_entries({ $attr => $args[1] }); }
    }

sub set
    {
        my(@args) = @_;
        
        if($args[0] =~ /^\d+$/) { set_entry_attr(@args); } # $n, $attr, $val
        else                    { set_data(@args);       } # $attr, $val
    }

sub list
    {
        my(@args) = @_;
        
        
        my @table = get_table();
        
        for my $line (@table)
            {
                my($path, $name) = $line =~ /(.+?) (.+)/;
                
                if(defined $args[0])
                    {
                        if($args[0] eq 'all')
                            {
                                print "\n $name: $path\n";
                                print_entries( { s => 'yet' }, win_path($path) );
                            }
                        elsif( $name eq $args[0] )
                            {
                                print "\n $name: $path\n";
                                print_entries( { s => 'yet' }, win_path($path) );
                            }
                    }
                else
                    {
                        print "\n$name: $path";
                    }
            }
        
        print "\n";
    }

sub not_valid
    {
        my($com) = @_;
        
        print "td: $com is not a valid command.\n\n";
        
        print_help();
    }

sub print_help
    {
print <<"END"
usage: td [init|i] [close|c] [add|a <entry> (-t tag)] [rm <entry n>]
          [done|d (entry n)] [set|s (entry n) <attr> <val>]
          [filter|f <attr> <val>] [list|l (all|<name>)] [help|h]


    init    - Initializes td project.
    
    close   - Closes td project.
    
    add     - Adds entry to todo.txt.
              
              Example: td add abcd | td add abcd -t TEST
    
    rm      - Removes entry from todo.txt
    
              Example: td rm 10
    
    done    - Either shows all entries marked as down or set an entry done (being a special case of td set <n> s done)
    
              Example: td done | td done 10
    
    set     - Sets an entry attribute (if an entry n is provided) or a global variable.
    
              Example: td set version 0.1.1 | td set 10 tag TEST
    
    filter  - Filter results by entry with one arguments or by attribute with two.
    
              Example: td filter test | td filter version 0.1.0
    
    list    - List all or some opened td projects
              
              Example: td list all | td list abcd
    
    help    - Shows this help
    
    all     - Not implemented

END
;
exit();
    }

sub com_help
    {
        my($com) = @_;

        print $com eq 'init'   ? "td: Usage - td init\n"                                                :
              $com eq 'close'  ? "td: Usage - td close\n"                                               :
              $com eq 'add'    ? "td: Usage - td add <entry> [-t tag]\n"                                :
              $com eq 'rm'     ? "td: Usage - td rm <entry>\n"                                          :
              $com eq 'done'   ? "td: Usage - td done [<entry>]\n"                                      :
              $com eq 'set'    ? "td: Usage - td set [n] <attr> <val>\n"                                :
              $com eq 'filter' ? "td: Usage - td filter [v|version|n|number|t|tag|s|status] <match>\n"  :
              $com eq 'list'   ? "td: Usage - td list [all] [<name>]\n"                                 :
              $com eq 'help'   ? "td: Usage - td help [-t <tag>]\n"                                     :
              $com eq 'all'    ? "td: Usage - td all\n"                                                 :
                                 "Error.";
        
        exit();
    }

sub process_arguments
    {
        my $com = splice(@ARGV, 0, 1);
        my @args = @ARGV;
        
        
        ($com eq 'init'   or $com eq 'i')   ?    init       (@args)     :
        ($com eq 'close'  or $com eq 'c')   ?    _close     (@args)     :
        ($com eq 'add'    or $com eq 'a')   ?    add        (@args)     :
        ($com eq 'rm')                      ?    rm         (@args)     :
        ($com eq 'done'   or $com eq 'd')   ?    done       (@args)     :
        ($com eq 'set'    or $com eq 's')   ?    set        (@args)     :
        ($com eq 'filter' or $com eq 'f')   ?    filter     (@args)     :
        ($com eq 'list'   or $com eq 'l')   ?    list       (@args)     :
        ($com eq 'help'   or $com eq 'h')   ?    print_help (@args)     :
        ($com eq 'all'    or $com eq 'a')   ?    'Not implemented.'     :
                                                 not_valid($com);
    }


##
# Set environment and current directory constants
# In cygwin, ARGV[0] is -cygwin and ARGV[1] is the file's path
##
if(scalar @ARGV > 0)
    {
        if($ARGV[0] eq '-cygwin')
            {
                $_ENV  = 'cygwin';
                $_PATH = $ARGV[1];
                $_DIR  = current_dir_cygwin($_PATH);
                
                splice(@ARGV, 0, 2);
            }
        else
            {
                $_ENV  = 'linux';
                $_PATH = current_path();
                $_DIR  = current_dir();
            }
    }

if(scalar @ARGV == 0)
    {
        print_entries({ s => 'yet' });
        exit();
    }


process_arguments();
