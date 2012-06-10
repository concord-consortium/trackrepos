# trackrepos

Command line tool that parses a yaml file in a directory to update and report on a collection of repositories.

## Installation

Install the Ruby Gem `track-repos`:

    gem install track-repos

## Setup

Create a `.tracked-repos.yaml` file to update and keep track of either existing git repositores or new ones you intend to add.

There are currently three types of git repositores that can be tracked andupdated:

1. Regular git repositories.
2. Git clones of Subversion repositories
3. Git clones of git mirrors of subversion repositories (need to explicity request new tags).

Here's an example yaml configuration file that tracks the Ruby Gems `aasm`, and `builder`.
Normally the master branch is fetched hower the specifiction for thr `builder` gem indicates that
the `trunk` branch should be checked out and tracked.In addition the `arduino` project which
is located in a Subersion repository is checked out as a git clone of a subversion repository.

    ---
    :git:
    - :path: aasm
      :remote: http://github.com/rubyist/aasm.git
    - :path: buildr
      :branch: trunk
      :remote: git://github.com/apache/buildr.git
    :git_svn:
    - :path: arduino
      :remote: http://arduino.googlecode.com/svn
    :git_clones_of_git_clones_of_svn_repos:
    - :path: ruby
      :branch: trunk
      :remote: git://github.com/ruby/ruby.git

The last item in the list specifies that the source code for Ruby should be checked out. In
this case it is being cloned from a git repository on github which is a miirror of the main
Ruby Subversion repository. This tpe if differentiated from a normal git repository because an
additional action is taken to manually fetch any updated tags.

The `.tracked-repos.yaml` file is a YAML serialization of the kind of data expressed in this Ruby Hash.
Each type of external repositor consists of an array of repository specificationns with keys for
`:path` and `:remote` git url, as well as an optional key for the `:branch` that should be tracked
The defatult is the master branch and does not need to be specified.

    { :git =>
        [
          { :path=>"aasm-git",
            :remote=>"http://github.com/rubyist/aasm.git" },
          { :path=>"buildr-git",
            :branch=>"trunk",
            :remote=>"git://github.com/apache/buildr.git" }
        ],
      :git_svn =>
        [
          { :path => "arduino-svn-git",
            :remote => "http://arduino.googlecode.com/svn" }
        ],
      :git_clones_of_git_svn_mirrors_of_svn_repos =>
        [
          { :path => "ruby-git",
            :branch => "trunk",
            :remote => "git://github.com/ruby/ruby.git" }
        ]
    }

## Usage

Change to the directory with the `.tracked-repos.yaml` file and run the command-line tool:

    track-repos

### help

    $ bin/trackrepos --help
    Usage: trackrepos
        -s YAMLFILE,                     Use specification file YAMLFILE instead of '.tracked-repos.yaml'
            --specification-file
        -d YAMLDIRECTORYFILE,            Use specification file YAMLDIRECTORYFILE instead of '.tracked-directories.yaml'
            --directory-file
        -v, --verbose                    Display yaml specification file
        -g, --generate                   Generate and display yaml specification suitable for a '.tracked-repos.yaml'
                                         file from existing repositories

### Tracking directories

You can also use a yaml specification file that just has lists of paths with yaml repository specifications.

The defautt name for a directory tracking file: `.tracked-directories.yaml`

This directory tracking file would cause `trackrepos` to process yaml repository specifications
in both `dir1/` and `dir2/`

    ---
    - dir1
    - dir2

### Specifying different names for yaml specification files

This example looks in the file `tracked-directories.yaml` in the current directory
and looks for the file `tracked-repos.yaml` in each of the directroies it references.

    $ trackrepos -d tracked-directories.yaml -s tracked-repos.yaml

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
