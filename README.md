# trackrepos

Command line tool that parses a yaml file in a directory to update and report on a collection of repositories.

## Installation

Install the Ruby Gem `trackrepos`:

    gem install trackrepos

## Setup

Create a `.tracked-repos.yaml` file to update and keep track of either existing git repositories or new ones you intend to add.

There are currently three types of git repositories that can be tracked and updated:

1. Regular git repositories.
2. Git clones of Subversion repositories
3. Git clones of git mirrors of subversion repositories (need to explicitly request new tags).

Here's an example yaml configuration file that tracks the Ruby Gems `aasm`, and `builder`.
Normally the master branch is fetched however the specifiction for thr `builder` gem indicates that
the `trunk` branch should be checked out and tracked.  In addition the `arduino` project which
is located in a Subersion repository is checked out as a git clone of a subversion repository.

file: .tracked-repos.yaml

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
Ruby Subversion repository. This type if differentiated from a normal git repository because an
additional action is taken to manually fetch any updated tags.

### tracked-repos.yaml examples

1. [Ruby Gems](https://raw.github.com/gist/2907585/gems-tracked-repos.yaml)
2. [JavaScript](https://raw.github.com/gist/2907585/javascript-tracked-repos.yaml)

Running: trackrepos in a directory with a file in that format named `.tracked-repos.yaml` will update (checking out the repo if it doesn't exist locally) and summarize the newest and oldest projects that were updated.

Here's a truncated version of the console output when running trackrepos in the directory that contains
the javascript yaml tracking file linked above.

    =======================================================================================

    Tracking git repositories in directory: /Users/stephen/dev/javascript

      Updating local git clones of external git repositories
      commands: git pull

        accordion-git                                           3 years, 4 months ago
        accordion-js-git                                        3 years, 5 months ago
        ajax_org/ace-git                                        25 hours ago
        ajax_org/gherkin-editor-git                             11 months ago
        ...

    -----------------------------------------------------------------------------------

      Updating local git clones of external subversion repositories
      commands: git svn rebase

        asciimathml-svn-git                                     4 years, 8 months ago
        canvas/canvas-text-svn-git                              1 year, 10 months ago
        canvas/excanvas-svn-git                                 3 years, 5 months ago
        canvas/canvg-svn-git                                    2 weeks ago
        closure-compiler-svn-git                                3 days ago
        ...

Which ends with a summary like this:

    =======================================================================================

      Git repositories in directory: /Users/stephen/dev/javascript
      updated in the last week:

        mvc/ember/ember-git                                     2 hours ago
        node/modules/express-git                                4 hours ago
        node/npm-git                                            4 hours ago
        underscore-git                                          5 hours ago
        mvc/angular/angular.js-git                              7 hours ago
        maqetta-git                                             8 hours ago
        jquery-ui-git                                           23 hours ago
        ajax_org/ace-git                                        25 hours ago
        testing/phantomjs-git                                   26 hours ago
        node/node-git                                           29 hours ago
        editors/codemirror2-git                                 2 days ago
        webgl/webgl-svn-git                                     2 days ago
        Modernizr-git                                           2 days ago
        ...

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

    trackrepos

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
