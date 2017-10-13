#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Cwd;
use File::Basename;
use Getopt::Long;


our $_ENV;
our $_PATH;
our $_DIR;                                                    

our $_VERSION        = '0.1.0';                               # Current version
our $_CYGWIN_PATH    = 'C:/cygwin64/';                        # Cygwin installation folder
our $_TABLE_PATH     = $ENV{'HOME'}.'/.td/project_table.txt'; # Path of project table
our $_BACKUP_PATH    = $ENV{'HOME'}.'/.td/backup.txt';        # Path of project table backup
our($_LINES, $_COLS) = `stty size` =~ /(\d+) (\d+)/;          # Number of lines and columns of the terminal


# If $| is not set to -1, prints are not shown before getting STDIN
$| = -1;


#---------------------------------------------
# Name        : current_path
# Description : Return current relative path
# Takes       : Nothing
# Returns     : path (string) - Current path
# Notes       : Nothing
# TODO        : Nothing
#---------------------------------------------
sub current_path
    {
        my $path;
        
        # If environment is cygwin
        #$path = `cygpath --windows --absolute $_[0]`;
        #chomp $path;
        
        # Else
        $path = File::Basename::dirname( Cwd::abs_path($0) );
        
        return $path;
    }

#-----------------------------------------------------
# Name        : abs_path
# Description : Get absolute path of a relative path
# Takes       : path (string) - Relative path
# Returns     : path (string) - Absolute path
# Notes       : Nothing
# TODO        : Nothing
#-----------------------------------------------------
sub abs_path
    {
        my($path) = @_;
        
        # If environment is cygwin
        $path = `cygpath --windows --absolute $path`;
        chomp $path;
        
        return $path;
    }

#-----------------------------------------------------
# Name        : current_dir
# Description : Returns current directory from a path
# Takes       : path (string) - File path
# Returns     : dir  (string) - Current directory
# Notes       : Nothing
# TODO        : Nothing
#-----------------------------------------------------
sub current_dir
    {
        my($path) = @_;
        my $dir;
        
        # If environment is cygwin
        $dir = ( split(/\//, $path) )[-1];
        
        # Else
        #return ( split( /\//, current_path() ) )[-1];
        
        return $dir;
    }

#-----------------------------------------------------
# Name        : win_path
# Description : Convert linux path into windows path
# Takes       : path (string) - Linux path
# Returns     : (string) - Windows path
# Notes       : Nothing
# TODO        : Nothing
#-----------------------------------------------------
sub win_path
    {
        my($path) = @_;
        
        $path = substr($path, 1);
        $path =~ s/\\/\//;
        
        return $_CYGWIN_PATH . $path;
    }

sub check_file
    {
        my($path, $file) = @_;
        
        if(-e "$path/.td")
            {
                print "\ntd: Couldn't access to $file.\n";
            }
        else
            {
                print "\ntd: There isn't a td project in this folder.\n";
            }
        
        exit();
    }

#------------------------------------------------------
# Name        : get_name_path
# Description : Get a project path from the name
# Takes       : target_name (string) - Target name
# Returns     : path (string) - Project path
#               (unref)       - If there was no match
# Notes       : Nothing
# TODO        : Nothing
#------------------------------------------------------
sub get_name_path
    {
        my($target_name) = @_;
    
        my @table = get_table();
        
        for my $line (@table)
            {
                my($path, $name) = $line =~ /(.+) (.+)/;
                
                return $path if $name eq $target_name;
            }
        
        return undef;
    }

#---------------------------------------------------
# Name        : fix_list
# Description : Fix project list non-existing path
# Takes       : Nothing
# Returns     : Nothing
# Notes       : Nothing
# TODO        : Nothing
#---------------------------------------------------
sub fix_list
    {
        my @table = get_table();
        
        for my $line (@table)
            {
                my($path, $name) = $line =~ /(.+) (.+)/;
                
                my $abs_path = abs_path("$path/.td/data.txt");
                
                if( !-e $abs_path and !-e "$path/.td/data.txt" )
                    {
                        print "Removed from table: $path\n";
                        
                        remove_from_table($path);
                    }
            }
    }

#---------------------------------------------
# Name        : date
# Description : Return formatted date
# Takes       : Nothing
# Returns     : (string) - dd/mm/yy
#               (string) - hh:mm:ss
# Notes       : Nothing
# TODO        : Nothing
#---------------------------------------------
sub date
    {
        my($s, $min, $h, $d, $m, $y) = localtime(time());
        
        for($s, $min, $h, $d, $m) { $_ = "0$_" if length $_ == 1; }
        
        $m++;
        $y += 1900;
        
        return("$d/$m/$y", "$h:$min:$s");
    }

#----------------------------------------------
# Name        : get_table
# Description : Read table of td projects
# Takes       : Nothing
# Returns     : table (array) - Project table
# Notes       : Nothing
# TODO        : Nothing
#----------------------------------------------
sub get_table
    {
        open(TABLE, '<', $_TABLE_PATH) or check_file($_TABLE_PATH, 'project table');
            my @table = <TABLE>;
            my $len   = scalar @table;
            
            chomp @table;
        close(TABLE);
        
        return @table;
    }

#-----------------------------------------------
# Name        : add_to_table
# Description : Add project to project table
# Takes       : path (string) - Project's path
#               name (string) - Project's name
# Returns     : Nothing
# Notes       : Nothing
# TODO        : Nothing
#-----------------------------------------------
sub add_to_table
    {
        my($path, $name) = @_;
        
        
        # Copy to backup before print
        my @table = get_table();
        
        open(BACKUP, '>', $_BACKUP_PATH)  or check_file($_BACKUP_PATH, 'project table backup');
            print BACKUP "$_\n" foreach @table;
        close(BACKUP);
        
        
        open(TABLE, '>>', $_TABLE_PATH)  or check_file($_TABLE_PATH, 'project table');
            print TABLE "$path $name\n";
        close(TABLE);
    }

#----------------------------------------------------
# Name        : remove_from_table
# Description : Remove project from project table
# Takes       : curr_path (string) - Path to remove
# Returns     : (true)  - On match
#               (undef) - Otherwise
# Notes       : Nothing
# TODO        : Nothing
#----------------------------------------------------
sub remove_from_table
    {
        my($curr_path) = @_;
        my $path;
        
        
        my @table = get_table();
        my $len   = scalar @table;
        
        return undef if $len == 0;
        
        
        # Copy to backup before print
        open(BACKUP, '>', $_BACKUP_PATH)  or check_file($_BACKUP_PATH, 'project table');
            print BACKUP "$_\n" foreach @table;
        close(BACKUP);
        
        
        # Remove entry if there is a match
        for(my $i = 0; $i < $len; $i++)
            {
                $path = ( split(' ', $table[$i]) )[0];
                
                if($path eq $curr_path)
                    {
                        splice(@table, $i, 1);
                        
                        open(TABLE, '>', $_TABLE_PATH)  or check_file($_TABLE_PATH, 'project table');
                            print TABLE "$_\n" foreach @table;
                        close(TABLE);
                        
                        return 1;
                    }
            }
        
        
        return undef;
    }

sub check_table_name
    {
        my($target_name) = @_;
        my $yn;
        
        my @table = get_table();
        
        for my $entry (@table)
            {
                my($path, $name) = $entry =~ /(.+) (.+)$/;
                
                if($target_name eq $name)
                    {
                        print "There is a project named $target_name already. Proceed? (Y): ";
                        $yn = <STDIN>;
                        chomp $yn;
                        
                        if($yn eq '' or $yn =~ /^[yY]$/)
                            {
                                return;
                            }
                        else
                            {
                                print "Project initialization aborted.\n";
                                exit();
                            }
                    }
            }
    }

#--------------------------------------------------------
# Name        : get_data
# Description : Get data.txt variable
# Takes       : var  (string) - Variable to get
#               path (string) - data.txt path (optional)
# Returns     : (string) - Variable value
#               (undef)  - If there was no match
# Notes       : Nothing
# TODO        : Nothing
#---------------------------------------------------------
sub get_data
    {
        my($var, $path) = @_;
        
        $path ||= '.';

        open(DATA, '<', "$path/.td/data.txt") or check_file($path, 'data.txt');
            for my $line (<DATA>)
                {
                    if( $line =~ /$var=(.+)\n/ )
                        {
                            close(DATA);
                            
                            return $1;
                        }
                }
        close(DATA);
        
        return undef;
    }

#---------------------------------------------------------
# Name        : set_data
# Description : Set data.txt variable
# Takes       : var  (string) - Variable to set
#               val  (string) - Value to set
#               path (string) - data.txt path (optional)
# Returns     : (string) - Variable data
#               (undef)  - On failure
# Notes       : Careful with die on len == 0
# TODO        : Nothing
#---------------------------------------------------------
sub set_data
    {
        my($var, $val, $path) = @_;
        
        $path ||= '.';
        
        open(DATA, '<', "$path/.td/data.txt") or check_file($path, 'data.txt');
            my @data = <DATA>;
            my $len  = scalar @data;
            
            chomp @data;
        close(DATA);
        
        die if $len == 0; ####
        
        
        for my $i (0...$len)
            {
                if( $data[$i] =~ /$var=/ )
                    {
                        $data[$i] = "$var=$val";
                        
                        open(DATA, '>', "$path/.td/data.txt") or check_file($path, 'data.txt');
                            print DATA "$_\n" foreach @data;
                        close(DATA);
                        
                        return 1;
                    }
            }
        
        return undef;
    }

#----------------------------------------------
# Name        : get_entry_attr
# Description : Split entry string attributes
# Takes       : line (string) - Entry
# Returns     : (array) - Entry attributes
# Notes       : Nothing
# TODO        : Nothing
#----------------------------------------------
sub get_entry_attr
    {
        my($line) = @_;
        
        my($n, $tag, $status, $version, $date, $hour, $entry) =
            $line =~ /n=(\d+) t=(.+?) s=(.+?) v=(.+?) d=(.+?) h=(.+?) e=(.+)/;
        
        return { n => $n, t => $tag, s => $status, v => $version, d => $date, h => $hour, e => $entry };
    }

#-------------------------------------------------
# Name        : set_entry_attr
# Description : Set entry attribute
# Takes       : n    (string) - Entry number
#               attr (string) - Attribute to set
#               val  (string) - Value to set
# Returns     : (true)  - On success
#               (undef) - On failure
# Notes       : Nothing
# TODO        : Nothing
#-------------------------------------------------
sub set_entry_attr
    {
        my($n, $attr, $val) = @_;
        my $found = undef;
        my %attr = ();
        
        
        open(TODO, '<', "./.td/todo.txt") or check_file('.', 'todo.txt');
            my @todo = <TODO>;
            chomp @todo;
        close(TODO);
        
        
        for my $i (0...scalar @todo-1)
            {
                if( ( split(' ', $todo[$i]) )[0] eq "n=$n" )
                    {
                        %attr = %{ get_entry_attr($todo[$i]) };
                        $attr{$attr} = $val;
                        
                        $todo[$i] = "n=".$attr{'n'}." t=".$attr{'t'}." s=".$attr{'s'}." v=".$attr{'v'}." "
                                  . "d=".$attr{'d'}." e=".$attr{'e'};
                        
                        $found = 1;
                        last;
                    }
            }
        
        if($found)
            {
                open(TODO, '>', "./.td/todo.txt") or check_file('.', 'todo.txt');
                    print TODO "$_\n" foreach @todo;
                close(TODO);
            }
        else
            {
                print "\ntd: Entry with number $n doesn't exist.\n";
                exit();
            }
        
        
        return $found;
    }

#----------------------------------------------------------
# Name        : add_entry
# Description : Add entry
# Takes       : entry (string) - Entry to add
#               tag   (string) - Tag to set
#               path  (string) - data.txt path (optional)
# Returns     : Nothing
# Notes       : Nothing
# TODO        : Nothing
#----------------------------------------------------------
sub add_entry
    {
        my($entry, $tag, $path) = @_;
        
        $path ||= '.';
        
        my $n            = get_data('n', $path)+1;
        my($date, $hour) = date();
        my $status       = 'yet';
        my $version      = get_data('version', $path);
        
        
        open(TODO, '>>', "$path/.td/todo.txt") or check_file($path, 'todo.txt');
            print TODO "n=$n t=$tag s=$status v=$version d=$date h=$hour e=$entry\n";
        close(TODO);
        
        
        set_data('n', $n, $path);
    }

#----------------------------------------------------
# Name        : remove_entry
# Description : Removes an entry
# Takes       : n (string) - Entry number to remove
# Returns     : (true)  - On success
#               (undef) - On failure
# Notes       : Nothing
# TODO        : Nothing
#----------------------------------------------------
sub remove_entry
    {
        my($n) = @_;
        
        
        open(TODO, '<', "./.td/todo.txt") or check_file('.', 'todo.txt');
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
                        
                        open(TODO, '>', "./.td/todo.txt") or check_file('.', 'todo.txt');
                            print TODO "$_\n" foreach @todo;
                        close(TODO);
                        
                        return 1;
                    }
            }
        
        return undef;
    }

#----------------------------------------------------------------------------
# Name        : format_text
# Description : 
# Takes       : 
# Returns     :
# Notes       :
# TODO        : Document
#----------------------------------------------------------------------------
sub format_text
    {
        my($text, $option, $name) = @_;
        my $RESET_SEQ = "\e[0m";
        
        
        if($option eq 'foreground')
            {
                $text = "\e[38;5;" . $name . "m" . $text . $RESET_SEQ;
            }
        elsif($option eq 'background')
            {
                $text = "\e[48;5;" . $name . "m" . $text . $RESET_SEQ;
            }
        elsif($option eq 'format')
            {
                $name =
                    $name eq 'bold'  ? 1 :
                    $name eq 'dim'   ? 2 :
                    $name eq ''      ? 3 :
                    $name eq 'under' ? 4 :
                                       7;

                $text = "\e[" . $name . "m" . $text . $RESET_SEQ;
            }
        
        
        return $text;
    }

#----------------------------------------------------------------------------
# Name        : print_entries
# Description : Format and print entries
# Takes       : hashref (hashref) - Attributes to filter
#               path    (string)  - Path to read (optional)
# Returns     : Nothing
# Notes       : No warnings to avoid a warning on a hash of array of hashes
# TODO        : Nothing
#----------------------------------------------------------------------------
sub print_entries
    {
        no warnings "experimental::autoderef";
        my($hashref, $path) = @_;
        
        
        if( not defined $path and !-e "./.td/todo.txt")
            {
                print "td: There is not a td project in this folder. Have a look at td help.\n";
                print "\nMaybe you meant td init?\n\n";
                
                return undef;
            }
        
        
        my %filter = %{$hashref};
        $path      = defined $path ? abs_path($path) : '.';
        
        my %entry    = ();
        my %tags     = ();
        my %attr_len = ( n => 0, s => 0, v => 0, d => 0, e => 0 , t => 0 );
        
        
        open(TODO, '<', "$path/.td/todo.txt") or check_file($path, 'todo.txt');
            my @todo = <TODO>;
            chomp @todo;
        close(TODO);
        
        if(scalar @todo == 0)
            {
                print "\nThere are no entries yet.\n\n";
                return;
            }
        
        
        ##
        # Get entries
        ##
        ENTRY:
        for(my $i = 0; $i < scalar @todo; $i++)
            {
                my %attr = %{ get_entry_attr( $todo[$i] ) };
                
                for my $key (keys %filter)
                    {
                        if($key eq 'e')
                            {
                                my $entry = $filter{$key};
                                next ENTRY if $attr{$key} !~ /$entry/;
                            }
                        elsif($key eq 't')
                            {
                                next ENTRY if $filter{$key} ne $attr{$key};
                            }
                        elsif( defined $attr{$key} and $attr{$key} ne $filter{$key} )
                            {
                                next ENTRY;
                            }
                    }

                $attr_len{'n'} = length($attr{'n'}) if length($attr{'n'}) > $attr_len{'n'};
                $attr_len{'v'} = length($attr{'v'}) if length($attr{'v'}) > $attr_len{'v'};
                $attr_len{'d'} = length($attr{'d'}) if length($attr{'d'}) > $attr_len{'d'}; ####
                $attr_len{'e'} = length($attr{'e'}) if length($attr{'e'}) > $attr_len{'e'};
                $attr_len{'t'} = length($attr{'t'}) if length($attr{'t'}) > $attr_len{'t'};
                
                
                # Initialize tag
                $tags{$attr{'t'}} ||= [];
                
                push( @{$tags{$attr{'t'}}}, {%attr});
            }
        
        
        # tag hash
        #   -> entries array
        #       -> entry hash
        for my $tag (sort keys %tags)
            {
                print "\n\n";
                print "   $tag\n";
                print " " . format_text(" " x ( length($tag)+2)."  ", 'format', 'under') . "\n\n";
                
                for my $tag_arr ( $tags{$tag} )
                    {
                        my @tag_arr = @{$tag_arr};
                        
                        for my $i ( 0... scalar @tag_arr-1 )
                            {
                                my %attr = %{ $tag_arr[$i] };
                                
                                $attr{'n'} = " ["
                                    . ( ' ' x ( $attr_len{'n'} - length( $attr{'n'} ) + 1 ) )
                                    . $attr{'n'}
                                    ." ]";
                                
                                $attr{'e'} .= ' ' x ( $attr_len{'e'} - length($attr{'e'}) );
                                
                                
                                my $line = $attr{'n'}."  ".$attr{'e'};
                                $line   .= ' ' x ($_COLS - length($line) - length( 'v'.$attr{'v'}." at ".$attr{'d'}) - 4);
                                $line   .= 'v'.$attr{'v'}." at ".$attr{'d'};
                                
                                
                                print "$line\n";
                                #print $attr{'dc'} if $attr{'dc'} ne 'null';
                            }
                    }
            }
        
        
        print "\n";
    }

#---------------------------------------------------
# Name        : init_files
# Description : Initialize all files on init
# Takes       : name    (string) - Project name
#               version (string) - Project version
# Returns     : Nothing
# Notes       : Nothing
# TODO        : Nothing
#---------------------------------------------------
sub init_files
    {
        my($name, $version) = @_;
    
        my $n    = 0;
        my $date = date();
        
        
        ##
        # Try to create .td folder and exit if can't
        ##
        mkdir "./.td";
        
        if(!-e './.td')
            {
                print 'td: Could not create .td folder.';
                exit();
            }
        
        
        open(DATA, '>', "./.td/data.txt") or die "Couldn\'t create data.txt\n";
            print DATA "name=$name\n"
                , "n=$n\n"
                , "version=$version\n"
                , "init_date=$date\n";
        close(DATA);
        
        
        open(TODO, '>', "./.td/todo.txt") or die "Couldn\'t create todo.txt\n";
        close(TODO);
    }

#--------------------------------------------
# Name        : init
# Description : Initialize project
# Takes       : Nothing
# Returns     : Nothing
# Notes       : Nothing
# TODO        : Nothing
#--------------------------------------------
sub init
    {
        my($name, $version, $yn);
        my $init_version = '0.1.0';
        
        
        ##
        # Initialize td with user input
        ##
        print "Project name ($_DIR): ";
        
        $name = <STDIN>;
        chomp $name;
        
        $name ||= $_DIR;
        
        
        # Check if there is already a project with the same name
        check_table_name($name);
        
        
        print "Initial version ($init_version): ";
        
        $version = <STDIN>;
        chomp $version;
        
        $version ||= $init_version;
        
        
        ##
        # Add to project table and create folder
        ##
        if( -e "./.td" )
            {
                print "td: Cannot create project $name - It already exists.\n";
            }
        else
            {
                ##
                # Check if it's already in project table
                # and remove it if so
                ##
                remove_from_table($_PATH);
                
                add_to_table($_PATH, $name);
                
                init_files($name, $version);
                
                print "td: Project $name initializated.\n";
            }
    }

#------------------------------
# Name        : _close
# Description : Close project
# Takes       : Nothing
# Returns     : Nothing
# Notes       : Nothing
# TODO        : Nothing
#------------------------------
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
        print 'Confirm (N): ';
        
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

#--------------------------------------------------------------
# Name        : add
# Description : Add entry
# Takes       : entry (string) - Entry to add
#               tag   (string) - Tag to set (optional)
#               name  (string) - Project to add to (optional)
# Returns     : Nothing
# Notes       : Nothing
# TODO        : Nothing
#--------------------------------------------------------------
sub add
    {
        my @tag;
        my $name;
        
        GetOptions( 't|tag=s{1,}' => \@tag, 'to=s{1,}' => \$name );
        
        
        my $tag = scalar @tag == 0 ? 'TODO' : join(' ', @tag);

        my $entry = join(' ', @ARGV);
        com_help('add') if not defined $entry;
        
        if(!$name)
            {
                add_entry($entry, $tag || 'TODO');
                print_entries({ s => 'yet' });
            }
        else
            {
                my $path = get_name_path($name);
                
                if(!$path)
                    {
                        print "There are no projects with name $name.\n";
                    }
                else
                    {
                        $path = abs_path($path);
                        
                        add_entry( $entry, $tag || 'TODO', $path );
                        
                        print_entries({ s => 'yet' }, $path);
                    }
            }
    }


#------------------------------------------
# Name        : rm
# Description : Remove entry
# Takes       : n (string) - Entry number
# Returns     : Nothing
# Notes       : Nothing
# TODO        : Argument check
#------------------------------------------
sub rm
    {
        my($n) = @ARGV;
        
        my $success = remove_entry($n);
        
        if($success) { print_entries({ s => 'yet' }); }
        else         { print "td: There is no such entry with that number.\n"; }
    }

#-----------------------------------------------------------
# Name        : done
# Description : Set an entry as done or print done entries
# Takes       : n (string) - Entry number (optional)
# Returns     : Nothing
# Notes       : Nothing
# TODO        : Nothing
#-----------------------------------------------------------
sub done
    {
        my($n) = @ARGV;
        
        if(not defined $n) { print_entries({ s => 'done' });  }
        else               { set_entry_attr($n, 's', 'done'); }
    }

#------------------------------------------------------------------------
# Name        : filter
# Description : Filter entries by attributes
# Takes       : args (array) - Attribute-Value pairs
# Returns     : Nothing
# Notes       : If there are no arguments, it filters by entry content
# TODO        : Argument check
#------------------------------------------------------------------------
sub filter
    {
        my %attr = ( t => [], e => [] );
        
        GetOptions
            (
                \%attr,
                'n=i',
                'v|version=s',
                't|tag=s{1,}',
                's|status=s',
                'e|entry=s{1,}'
            );

        for my $key ('e', 't')
            {
                if( scalar @{$attr{$key}} == 0 ) { delete $attr{$key}; }
                else                             { $attr{$key} = join( ' ', @{$attr{$key}} ); }
            }
        
        
        print_entries(\%attr);
    }

#--------------------------------------------------------------------
# Name        : set
# Description : Set data or entry attributes
# Takes       : args (array) - Either (n, attr, val) or (attr, val)
# Returns     : Nothing
# Notes       : Nothing
# TODO        : Nothing
#--------------------------------------------------------------------
sub set
    {
        my %attr = ( name => [], t => [], e => [] );
        my $data;
        
        GetOptions
            (
                \%attr, 'name=s{1,}', 'version=s', 'n=i', 't=s{1,}', 's=s', 'v=s', 'e=s{1,}',
                'data' => \$data
            );
        
        ##
        # Join arrays
        ##
        for my $key ('name', 't', 'e')
            {
                if( scalar @{$attr{$key}} == 0 ) { delete $attr{$key}; }
                else                             { $attr{$key} = join( ' ', @{$attr{$key}} ); }
            }
        
        
        if(defined $data)
            {
                for my $key (keys %attr)
                    {
                        next if $key !~ /^(?:name|version|n)$/;
                        
                        set_data( $key, $attr{$key} );
                    }
            }
        elsif(defined $attr{'n'})
            {
                for my $key (keys %attr)
                    {
                        next if $key !~ /^(?:t|s|v|e)$/;
                        
                        my $ret = set_entry_attr( $attr{'n'}, $key, $attr{$key} );
                        
                        if(!$ret) { print "td: Could not set attribute $key.\n"; }
                    }
                
                print_entries({ s => 'yet' });
            }
        else
            {
                com_help('set');
            }
    }

#-------------------------------------------------------------------------
# Name        : list
# Description : List td projects
# Takes       : args (array) - Either 'all' or a project name (optional)
# Returns     : Nothing
# Notes       : Nothing
# TODO        : Nothing
#-------------------------------------------------------------------------
sub list
    {
        my %attr = ( name => [] );
        
        GetOptions( \%attr, 'all', 'name=s{1,}' );
        
        ##
        # Join arrays
        ##
        if( scalar @{$attr{'name'}} == 0 ) { delete $attr{'name'}; }
        else                               { $attr{'name'} = join( ' ', @{$attr{'name'}} ); }
        
        my $attr_len = scalar keys %attr;
        
        
        # Check that all path in project table are correct
        fix_list();
        
        
        my @table = get_table();
      
        for my $line (@table)
            {
                my($path, $name) = $line =~ /(.+?) (.+)/;
                
                if($attr_len > 0)
                    {
                        if( defined $attr{'all'} )
                            {
                                print "\n$name: $path\n";
                                print_entries( { s => 'yet' }, win_path($path) );
                            }
                        elsif( defined $attr{'name'} and $name eq $attr{'name'} )
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

#-------------------------------------------
# Name        : not_valid
# Description : Handle non-valid arguments
# Takes       : com (string) - Command
# Returns     : Nothing
# Notes       : Nothing
# TODO        : Nothing
#-------------------------------------------
sub not_valid
    {
        my($com) = @_;
        
        print "td: $com is not a valid command.\n\n";
        
        print_help();
    }

#---------------------------------
# Name        : print_help
# Description : Prints the help
# Takes       : Nothing
# Returns     : Nothing
# Notes       : Exits at the end
# TODO        : Nothing
#---------------------------------
sub print_help
    {
print <<"END"
usage: td [init] [close] [add <entry> (-t <tag>) (-to <name>) ] [rm <entry n>]
          [done (-n <entry n>)] [set (-n <entry n>) <attr> <val>]
          [filter <attr> <val>] [list (-all|-name <name>)] [help]


    init
        Initialize td project.
    
    close
        Close td project.
    
    add
        Add an entry to todo.txt.
              
        Example: td add abcd | td add abcd -t TEST | td add abcd -to efgh
    
    rm
        Remove entry from todo.txt
    
        Example: td rm 10
    
    done
        Either show all entries marked as down or set an entry done
        (being a special case of td set <n> s done)
    
        Example: td done | td done 10
    
    set
        Set an entry attribute (if an entry n is provided) or a global variable.
    
        Example: td set -version 0.1.1 | td set -n 10 -t TEST
    
    filter
        Filter results by entry with one arguments or by attribute with two.
    
        Example: td filter -e test | td filter -v 0.1.0
    
    list
        List all or some opened td projects
              
        Example: td list -all | td list -name abcd
    
    help
        Show this help
    
    version
        Show current version

END
;
exit();
    }

#---------------------------------------
# Name        : com_help
# Description : Prints command help
# Takes       : com (string) - Command
# Returns     : Nothing
# Notes       : Exits at the end
# TODO        : Nothing
#---------------------------------------
sub com_help
    {
        my($com) = @_;
        

        my $line =
            $com eq 'init'   ? "usage: td init\n"                                                :
            $com eq 'close'  ? "usage: td close\n"                                               :
            $com eq 'add'    ? "usage: td add <entry> [-t tag]\n"                                :
            $com eq 'rm'     ? "usage: td rm <entry>\n"                                          :
            $com eq 'done'   ? "usage: td done [<entry>]\n"                                      :
            $com eq 'set'    ? "usage: td set [n] <attr> <val>\n"                                :
            $com eq 'filter' ? "usage: td filter [v|version|n|number|t|tag|s|status] <match>\n"  :
            $com eq 'list'   ? "usage: td list [all] [<name>]\n"                                 :
            $com eq 'help'   ? "usage: td help\n"                                                :
                               "Error.";
        
        print $line;
        
        exit();
    }

sub version
    {
        print "td version $_VERSION\n";
    }

#-------------------------------------------------
# Name        : process_arguments
# Description : Process command line arguments
# Takes       : Nothing
# Returns     : Nothing
# Notes       : Nothing
# TODO        : Nothing
#-------------------------------------------------
sub process_arguments
    {
        my $com  = splice(@ARGV, 0, 1);
        
        
        my $help = join(' ', @ARGV) =~ /^--?help$/ || undef;
        
        if(defined $help and $com !~ /help/) { com_help($com); }
        elsif(defined $help)                 { print_help(); }
        
        
        $com eq 'init'       ?    init       ()     :
        $com eq 'close'      ?    _close     ()     :
        $com eq 'add'        ?    add        ()     :
        $com eq 'rm'         ?    rm         ()     :
        $com eq 'done'       ?    done       ()     :
        $com eq 'set'        ?    set        ()     :
        $com eq 'filter'     ?    filter     ()     :
        $com eq 'list'       ?    list       ()     :
        $com eq 'help'       ?    print_help ()     :
        $com eq 'version'    ?    version    ()     :
                                  not_valid($com);
    }


##
# Set environment and current directory constants
##
$_PATH = $ARGV[0];
$_DIR  = current_dir($_PATH);

splice(@ARGV, 0, 1);


##
# Print entries if there are no arguments
##
if(scalar @ARGV == 0)
    {
        print_entries({ s => 'yet' });
        exit();
    }


process_arguments();
