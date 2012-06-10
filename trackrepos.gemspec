# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'trackrepos/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Stephen Bannasch"]
  gem.email         = ["sbannasch@concord.org"]
  gem.description   = %q{Uses yaml configuration files to track and update collections of external git repositories}
  gem.summary       = %q{Useful for tracking large numbers of external git repositories}
  gem.homepage      = "https://github.com/concord-consortium/trackrepos"
  gem.files         = `git ls-files`.split($\)
  gem.executable    = "trackrepos"
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "trackrepos"
  gem.require_paths = ["lib"]
  gem.version       = TrackRepos::VERSION

  gem.post_install_message = <<-HEREDOC

trackrepos

Create a '.tracked-repos.yaml' file to update and keep track of either existing git
repositores or new ones you intend to add.

There are currently three types of git repositores that can be tracked andupdated:

1. Regular git repositories.
2. Git clones of Subversion repositories
3. Git clones of git mirrors of subversion repositories (need to explicity request new tags).

Here's an example yaml configuration file that tracks the Ruby Gems `aasm`, and `builder`.
Normally the master branch is fetched hower the specifiction for thr `builder` gem indicates that
the `trunk` branch should be checked out and tracked.In addition the `arduino` project which
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
Ruby Subversion repository. This tpe if differentiated from a normal git repository because an
additional action is taken to manually fetch any updated tags.

  HEREDOC
end
