### td

use strict;
use warnings;
use diagnostics;

use Cwd qw{ abs_path };
use File::Basename qw{ dirname };
use Switch;
use DateTime;
use Text::Wrap;


$| = -1;


sub current_path   { return dirname( abs_path($0) ); }
sub current_folder { return ( split( /\\/, current_path() ) )[-1]; }
sub date           { return DateTime->now(); }

sub add_to_table
    {
        my($path, $name) = @_;
        
        open(TABLE, '<', './project_table.txt');
            my @table = <TABLE>;
            chomp(@table);
        close(TABLE);
            
        push(@table, "$path $name");
        
        open(TABLE, '>', './project_table.txt');
            print TABLE join("\n", @table);
        close(TABLE);
        
        return 1;
    }

sub remove_from_table
    {
        my($curr_path, $curr_folder) = @_;
        my $path;
        
        
        open(TABLE, '<', './project_table.txt');
            my @table = <TABLE>;
            my $len   = scalar @table;
            
            chomp @table;
        close(TABLE);
        
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

sub get_n
    {
        my $folder = current_folder();
    
        open(DATA, '<', "./projects/$folder/data.txt");
            for my $line (<DATA>)
                {
                    if( $line =~ /n=(\d+)/ ) { return $1; }
                }
        close(DATA);
        
        return undef;
    }

sub set_n
    {
        my($n)     = @_;
        my $folder = current_folder();
        
        open(DATA, '<', "./projects/$folder/data.txt");
            my @data = <DATA>;
            chomp @data;
        close(DATA);

        for my $i(0...scalar @data)
            {
                if( $data[$i] =~ /n=(\d+)/ )
                    {
                        $data[$i] = "n=$n";
                        
                        open(DATA, '>', "./projects/$folder/data.txt");
                            print DATA join("\n", @data);
                        close(DATA);
                        
                        return 1;
                    }
            }
        
        return undef;
    }

sub get_version
    {
        my $folder = current_folder();
    
        open(DATA, '<', "./projects/$folder/data.txt");
            for my $line (<DATA>)
                {
                    if( $line =~ /version=(.+)\n/ ) { return $1; }
                }
        close(DATA);
        
        return undef;
    }

sub set_version
    {
        ...
    }

sub add_entry
    {
        my($tag, $entry) = @_;
        
        my $folder = current_folder();
        
        my $n       = get_n()+1;
        my $date    = date();
        my $status  = 'yet';
        my $version = get_version();
        
        
        open(TODO, '>>', "./projects/$folder/todo.txt");
            print TODO "n=$n t=$tag s=$status v=$version d=$date e=$entry\n";
        close(TODO);
        
        
        set_n($n);
    }

sub remove_entry
    {
        my($n) = @_;
        
        my $folder = current_folder();
        
        
        ##
        # TODO: Add no arguments handler to process_arguments
        ##
        open(TODO, '<', "./projects/$folder/todo.txt");
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
                        
                        open(TODO, '>', "./projects/$folder/todo.txt");
                            print TODO join("\n", @todo);
                        close(TODO);
                        
                        return 1;
                    }
            }
        
        return undef;
    }

sub show_all_entries
    {
        ##
        # So that it doesn't throw a warning on a hash of array of hashes
        ##
        no warnings "experimental::autoderef";
        
        my($folder, $status) = @_;
        
        my %tags  = ();
        my $n_len = length(get_n());
        
        
        open(TODO, '<', "./projects/$folder/todo.txt");
            my @todo = <TODO>;
            chomp @todo;
        close(TODO);
        
        
        ##
        # Get entries
        ##
        for(my $i = 0; $i < scalar @todo; $i++)
            {
                my($n, $tag, $status, $version, $date, $entry) = $todo[$i] =~ /n=(\d+) t=(.+?) s=(.+?) v=(.+?) d=(.+?) e=(.+)/;
                
                ##
                # Initialize tag
                ##
                $tags{$tag} ||= [];
                
                #push( $tags{$tag}, { n => $n, status => $status, version => $version, date => $date, entry => $entry } );
                push( $tags{$tag}, [$n, $status, $version, $date, $entry] );
            }
        
        
        for my $tag (sort keys %tags)
            {
                print "\n\n";
                print "   $tag\n";
                print " --------\n\n";
                
                for my $tag_arr ( $tags{$tag} )
                    {
                        for my $entry ( @{ $tags{$tag} } )
                            {
                                my @entry = @{$entry};
                                my($n, $status, $version, $date, $entry) = @entry;
                                
                                continue if $status eq 'done';
                                
                                
                                $date =~ s/T/ /;
                                
                                $n = " [" . ( ' ' x ( $n_len-length($n) + 1 ) ) . "$n ]";
                                
                                my $line = "$n  $entry\t\t$version @ $date";
                                
                                #print $line, "\n";
                                my @a = ($n, $entry, $version, $date, "\n");
                                print Text::Wrap::fill("\t", "", @a);
                            }
                    }
            }
    }

sub init_data
    {
        my($folder, $version) = @_;
    
        my $n    = 0;
        my $date = date();
        
        open(DATA, '>', "./projects/$folder/data.txt");
            print DATA "n=$n\n", "version=$version\n", "init_date=$date";
        close(DATA);
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
        my $path   = current_path();
        my $folder = current_folder();
        my $init_version = '0.1.0';
        
        
        ##
        # Initialize td with user input
        ##
        print "Project name($folder): ";
        $name = <STDIN>;
        
        print "Initial version($init_version): ";
        $version = <STDIN>;
        
        
        ##
        # Set to default values if user pressed enter
        ##
        $name eq "\n"
            ? $name = $folder
            : chomp $name;
        $version eq "\n"
            ? $version = $init_version
            : chomp $version;
        
        
        ##
        # Add to project table and create folder
        # TODO: Under current implementation, there can only be one project with one name
        ##
        if( -e "./projects/$name" )
            {
                print "td: Cannot create project $name - It already exists.\n";
            }
        else
            {
                add_to_table($path, $name);
                    
                mkdir "./projects/$name";
                init_data($folder, $version);
                
                print "td: Project $name initializated.\n";
            }
    }

sub _close
    {
        my $curr_path   = current_path();
        my $curr_folder = current_folder();
        
        
        my $success = remove_from_table($curr_path, $curr_folder);
        
        
        ##
        # If there has been a match, remove project folder
        # TODO: Probably won't be able to remove non-empty folders
        # TODO: Add some security check on $curr_folder to avoid unintended deletions
        ##
        if($success)
            {
                if($curr_folder eq '') { return; }
            
                system("rm -rf ./projects/$curr_folder");
                rmdir "./projects/$curr_folder";
                
                print "td: Project $curr_folder closed.";
            }
        else
            {
                print "td: There isn't a td project in this folder.\n";
            }
    }

sub add
    {
        my($entry, $tag) = split(' -t ', join(' ', @_));
        
        $tag ||= 'TODO';
        
        add_entry($tag, $entry);
        
        show_all_entries( current_folder(), 'yet' );
    }
sub mv
    {
    }
sub rm
    {
        my($n) = @_;
        
        my $success = remove_entry($n);
        
        if($success)
            {
                show_all_entries( current_folder(), 'yet' );
            }
        else
            {
                print "td: There is no such entry with that number.\n";
            }
    }
sub done
    {
    }
sub active
    {
    }
sub show
    {
    }
sub not_valid
    {
        my($com) = @_;
        
        print "td: $com is not a valid command.\n";
        exit();
    }


##
# TODO: Entry edditing command
##
sub process_arguments
    {
        my $com = splice(@ARGV, 0, 1);
        my @args = @ARGV;
        
        
        if(scalar @args == 0)
            {
                show_all_entries( current_folder(), 'yet' );
                return;
            }
        
        switch($com)
            {
                case 'init'     { init   (@ARGV);  }
                case 'close'    { _close (@ARGV);  }
                case 'add'      { add    (@ARGV);  }
                case 'mv'       { mv     (@ARGV);  }
                case 'rm'       { rm     (@ARGV);  }
                case 'done'     { done   (@ARGV);  }
                case 'active'   { active (@ARGV);  }
                case 'show'     { show   (@ARGV);  }
                case 'up'       { ...              }
                case 'down'     { ...              }
                case 'v'        { ...              }
                case 'checkout' { ...              }
                else            { not_valid($com); }
            }
    }


process_arguments();