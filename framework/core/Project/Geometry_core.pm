#-------------------------------------------------------------------------------
# Copyright (c) 2014-2019 René Just, Darioush Jalali, and Defects4J contributors.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#-------------------------------------------------------------------------------

=pod

=head1 NAME

Project::Geometry_core.pm -- L<Project> submodule for commons-geometry.

=head1 DESCRIPTION

This module provides all project-specific configurations and subroutines for the
commons-geometry project.

=cut
package Project::Geometry_core;

use strict;
use warnings;

use Constants;
use Vcs::Git;

our @ISA = qw(Project);
my $PID  = "Geometry_core";

sub new {
    @_ == 1 or die $ARG_ERROR;
    my ($class) = @_;

    my $name = "commons-geometry";
    my $vcs  = Vcs::Git->new($PID,
                             "$REPO_DIR/$name.git",
                             "$PROJECTS_DIR/$PID/$BUGS_CSV_ACTIVE",
                             \&_post_checkout);

    return $class->SUPER::new($PID, $name, $vcs);
}

##
## Determines the directory layout for sources and tests
##
#sub determine_layout {
#    @_ == 2 or die $ARG_ERROR;
#    my ($self, $rev_id) = @_;
#    my $dir = $self->{prog_root};

#    # Add additional layouts if necessary
#    my $result = _ant_layout($dir) // _maven_layout($dir);
#    die "Unknown layout for revision: ${rev_id}" unless defined $result;
#    return $result;
#}

#
# Post-checkout tasks include, for instance, providing cached build files,
# fixing compilation errors, etc.
#
sub _post_checkout {
    my ($self, $rev_id, $work_dir) = @_;

    my $project_dir = "$PROJECTS_DIR/$self->{pid}";
    # Check whether ant build file exists
    unless (-e "$work_dir/build.xml") {
        my $build_files_dir = "$PROJECTS_DIR/$PID/build_files/$rev_id";
        if (-d "$build_files_dir") {
            Utils::exec_cmd("cp $build_files_dir/* $work_dir", "Copy generated Ant build file") or die;
        }
    }

     if (-e "$work_dir/build.xml"){
        rename("$work_dir/build.xml", "$work_dir/build.xml".'.bak');
        open(IN, '<'."$work_dir/build.xml".'.bak') or die $!;
        open(OUT, '>'."$work_dir/build.xml") or die $!;
        while(<IN>) {

            $_ =~ s/compile-tests/compile\.tests/g;
            #$_ =~ s/classesdir/classes\.dir/g;
            #$_ =~ s/testclasses\.dir/test\.classes\.dir/g;
            
            #support java8
            $_ =~ s/fork="false"/fork="true"/g;
            print OUT $_;
        }
        close(IN);
        close(OUT);
    }

    if (-e "$work_dir/maven-build.xml"){
        rename("$work_dir/maven-build.xml", "$work_dir/maven-build.xml".'.bak');
        open(IN, '<'."$work_dir/maven-build.xml".'.bak') or die $!;
        open(OUT, '>'."$work_dir/maven-build.xml") or die $!;
        while(<IN>) {
            $_ =~ s/compile-tests/compile\.tests/g;
            $_ =~ s/"src/"commons-geometry-core\/src/g;
            #$_ =~ s/classesdir/classes\.dir/g;
            #$_ =~ s/testclasses\.dir/test\.classes\.dir/g;
            
            #support java8
            $_ =~ s/fork="false"/fork="true"/g;
            print OUT $_;
        }
        close(IN);
        close(OUT);
    }
    if (-e "$work_dir/maven-build.properties"){
        rename("$work_dir/maven-build.properties", "$work_dir/maven-build.properties".'.bak');
        open(IN, '<'."$work_dir/maven-build.properties".'.bak') or die $!;
        open(OUT, '>'."$work_dir/maven-build.properties") or die $!;
        while(<IN>) {
            $_ =~ s/compile-tests/compile\.tests/g;
            $_ =~ s/=src/=commons-geometry-core\/src/g;
            #$_ =~ s/classesdir/classes\.dir/g;
            #$_ =~ s/testclasses\.dir/test\.classes\.dir/g;
            
            #support java8
            $_ =~ s/fork="false"/fork="true"/g;
            print OUT $_;
        }
        close(IN);
        close(OUT);
    }    

    #exclude the test you don't need
    if (-e "$work_dir/src/tests/junit/org/apache/tools/ant/taskdefs/xxx.java"){
        rename("$work_dir/src/tests/junit/org/apache/tools/ant/taskdefs/xxx.java", "$work_dir/src/tests/junit/org/apache/tools/ant/taskdefs/xxx.java".".bak");
        #open(OUT, '>'."$work_dir/src/tests/junit/org/apache/tools/ant/taskdefs/SQLExecTest.java") or die $!;
        #my $converted_file = `iconv -f iso-8859-1 -t utf-8 "$work_dir/src/tests/junit/org/apache/tools/ant/taskdefs/SQLExecTest.java.bak"`;
        #print OUT $converted_file;
        #close(OUT);
    }

}


#
# This subroutine is called by the bug-mining framework for each revision during
# the initialization of the project. Example uses are: converting and caching
# build files or other time-consuming tasks, whose results should be cached.
#
sub initialize_revision {
    my ($self, $rev_id, $vid) = @_;
    $self->SUPER::initialize_revision($rev_id);

    my $work_dir = $self->{prog_root};
    my $result; #= _ant_layout($work_dir) // _maven_layout($work_dir);
    my $subproject="commons-geometry-core";
    
   if (-e "$work_dir/src/main/java" and -e "$work_dir/src/test/java"){
        $result = {src=>"$subproject/src/main/java", test=>"$subproject/src/test/java"} unless defined $result;
    }
    elsif (-e "$work_dir/src/main/java" and -e "$work_dir/src/tests/java"){
        $result = {src=>"$subproject/src/main/java", test=>"$subproject/src/tests/java"} unless defined $result;
    }
    elsif (-e "$work_dir/src/main" and -e "$work_dir/src/testcases"){
        $result = {src=>"$subproject/src/main", test=>"$subproject/src/testcases"} unless defined $result;
    }
    elsif (-e "$work_dir/src/main" and -e "$work_dir/src/tests/junit"){
        $result = {src=>"$subproject/src/main", test=>"$subproject/src/tests/junit"} unless defined $result;
    }
    elsif (-e "$work_dir/src/main" and -e "$work_dir/src/tests"){
        $result = {src=>"$subproject/src/main", test=>"$subproject/src/tests"} unless defined $result;
    }
    elsif (-e "$work_dir/src/java" and -e "$work_dir/src/test"){
        $result = {src=>"$subproject/src/java", test=>"$subproject/src/test"} unless defined $result;
    }
    elsif (-e "$work_dir/src/java" and -e "$work_dir/src/tests"){
        $result = {src=>"$subproject/src/java", test=>"$subproject/src/tests"} unless defined $result;
    }
    else {
        system("tree -d $work_dir");
        die "Unknown directory layout" unless defined $result;
    }
    
    $self->_add_to_layout_map($rev_id, $result->{src}, $result->{test});
    $self->_cache_layout_map(); # Force cache rebuild
}

#
# Distinguish between project layouts and determine src and test directories.
# Each _layout subroutine returns undef if it doesn't match the layout of the
# checked-out version. Otherwise, it returns a hash that provides the src and
# test directory, relative to the working directory.
#

#
# Existing Ant build.xml and default.properties
#
sub _ant_layout {
    @_ == 1 or die $ARG_ERROR;
    my ($dir) = @_;
    my $src  = `grep "source.home" $dir/default.properties 2>/dev/null`;
    my $test = `grep "test.home" $dir/default.properties 2>/dev/null`;

    # Check whether this layout applies to the checked-out version
    return undef if ($src eq "" || $test eq "");

    $src =~ s/\s*source.home\s*=\s*(\S+)\s*/$1/;
    $test=~ s/\s*test.home\s*=\s*(\S+)\s*/$1/;

    return {src=>$src, test=>$test};
}

#
# Generated build.xml (from mvn ant:ant) with maven-build.properties
#
sub _maven_layout {
    @_ == 1 or die $ARG_ERROR;
    my ($dir) = @_;
    my $src  = `grep "maven.build.srcDir.0" $dir/maven-build.properties 2>/dev/null`;
    my $test = `grep "maven.build.testDir.0" $dir/maven-build.properties 2>/dev/null`;

    return undef if ($src eq "" || $test eq "");

    $src =~ s/\s*maven\.build\.srcDir\.0\s*=\s*(\S+)\s*/$1/;
    $test=~ s/\s*maven\.build\.testDir\.0\s*=\s*(\S+)\s*/$1/;

    return {src=>$src, test=>$test};
}

1;
