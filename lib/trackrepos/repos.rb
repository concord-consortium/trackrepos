require 'yaml'
require 'time'

module TrackRepos
  class Repos

    PATH_FORMAT_STR   = "    %-50s%-30s%-30s"
    COMMIT_FORMAT_STR = "  %-24s%s"

    TRACKED_YAML = '.tracked-repos.yaml'
    TRACKED_DIRECTORIES_YAML = '.tracked-directories.yaml'

    GIT_COMMANDS = {
      :git => [
        ['git pull'],
        'Updating local git clones of external git repositories'
      ],

      :git_svn_hybrid => [
        ['git svn rebase'],
        'Updating local git svn hybrid clones of external subversion repositories'
      ],
      :git_svn => [
        ['git svn rebase'],
        'Updating local git clones of external subversion repositories'
      ],
      :git_clones_of_git_clones_of_svn_repos => [
        ['git pull', 'git fetch -t'],
        'Updating local git clones of external git repositories which themselves are created from git-svn clones of svn repos'
      ]
    }

    def initialize(options)
      @options = options || {}
      @tracked_filename = @options[:tracked_filename] || TRACKED_YAML
      @tracked_directories = @options[:tracked_directories] || TRACKED_DIRECTORIES_YAML
      if File.exists?(@tracked_directories)
        @tracked_directories = YAML.load_file(@tracked_directories)
      else
        @tracked_directories = [ Dir.pwd ]
      end
      @tracked_collections = []
      @tracked_directories.each do |dir|
        dir_path = File.expand_path(dir)
        unless File.exists?(dir_path)
          raise <<-HEREDOC


*** ERROR : Directory: '#{dir}' doesn't exist.

          HEREDOC
        end
        tracking_spec_path = File.join(dir_path, @tracked_filename)
        unless File.exists?(tracking_spec_path)
          raise <<-HEREDOC


*** ERROR: YAML specification file does not exist: '#{tracking_spec_path}'

          HEREDOC
        end
        tracking_spec = YAML.load_file(tracking_spec_path)
        @tracked_collections <<  { 
          :dir => dir,
          :tracking_spec => tracking_spec,
          :repos => [],
          :repos_with_update_errors => { "git error" => [], "dir doesn't exist" => [] }
        }
      end
    end

    def track
      @tracked_collections.each do |collection|
        track_collection(collection)
        # FIXME: why are there duplicates ???
        collection[:repos].uniq!
        collection[:repos].sort! { |r1, r2| r2[1][:updated_date] <=> r1[1][:updated_date] }
      end
      @tracked_collections.each do |collection|
        report_results(collection)
      end

    end

    def track_collection(collection)
      dir = collection[:dir]
      tracking_spec = collection[:tracking_spec]
      Dir.chdir File.expand_path(dir) do
        puts <<-HEREDOC

=======================================================================================

Tracking git repositories in directory: #{dir}
        HEREDOC
        first_time = true
        tracking_spec.each do |type, tracked_repos|
          unless first_time
            puts <<-HEREDOC

-----------------------------------------------------------------------------------
            HEREDOC
          end
          commands = GIT_COMMANDS[type][0]
          desc = GIT_COMMANDS[type][1]
          update_local_gits(collection, type, tracked_repos, commands, desc)
          first_time = false
        end
      end
    end

    def update_local_gits(collection, type, tracked_repos, commands, message)
      dir = collection[:dir]
      if tracked_repos
        puts <<-HEREDOC

  #{message}
  commands: #{commands.join('; ')}

        HEREDOC
        tracked_repos.each do |tracked_repo|
          path = tracked_repo[:path]
          branch = tracked_repo[:branch] || 'master'
          remote = tracked_repo[:remote]
          if !File.exists?(path) && remote
            case type
            when :git
              cmd = "mkdir -p #{path}; git clone #{remote} #{path}"
            when :git_svn
              cmd = "mkdir -p #{path}; git svn clone #{remote} #{path}"
            end
            puts <<-HEREDOC

  Checking out new project #{remote}
  Into directory:          #{File.expand_path(dir, path)}

  command: #{cmd}

            HEREDOC
            `#{cmd}`
            puts
          end
          if File.exists?(path)
            git_remote = `git config --file #{path}/.git/config --get remote.origin.url`.strip
            git_svn_remote = `git config --file #{path}/.git/config --get svn-remote.svn.url`.strip
            if git_remote.empty?
              tracked_repo[:remote] = git_svn_remote
            else
              tracked_repo[:remote] = git_remote
            end
            git_command(dir, path, commands, collection, branch)
            if File.exists?(File.join(path, '.gitmodules'))
              git_command(dir, path, ['git submodule update --init --recursive'], collection, branch, { :quiet => true })
            end
          else
            puts <<-HEREDOC

  ERROR : Path: '#{path}' doesn't exist and failed to create new repository.

            HEREDOC
            collection[:repos_with_update_errors]["dir doesn't exist"] << path
          end
        end
      end
    end


    def report_results(collection)
      dir = collection[:dir]
      if collection[:repos].length > 20
        puts <<-HEREDOC

=======================================================================================

  Git repositories in directory: #{dir}
  updated in the last week:

        HEREDOC
        collection[:repos].find_all {|r| r[1][:updated_in_last_week] }.uniq.each  do |repo|
          puts sprintf(PATH_FORMAT_STR, repo[0].gsub(dir+ '/', ""), repo[1][:updated_relative], repo[1][:desc])
        end
        puts <<-HEREDOC

Least recently updated:

        HEREDOC
        collection[:repos][-15..-1].each  do |repo|
          puts sprintf(PATH_FORMAT_STR, repo[0].gsub(dir+ '/', ""), repo[1][:updated_relative], repo[1][:desc])
        end
      else
        puts <<-HEREDOC

=======================================================================================

  Git repositories sorted by when last updated : #{dir}

        HEREDOC
        collection[:repos].each  do |repo|
          puts sprintf(PATH_FORMAT_STR, repo[0].gsub(dir+ '/', ""), repo[1][:updated_relative], repo[1][:desc])
        end
      end

      if @options[:verbose]
        puts <<-HEREDOC

---------------------------------------------------------------------------------------

  YAML form of '#{collection[:dir]}/#{@tracked_filename}':

          HEREDOC
        puts collection[:tracking_spec].to_yaml
      end
      unless collection[:repos_with_update_errors].values.flatten.empty?
        puts <<-HEREDOC

=======================================================================================

  Error summary:

  The following git repositories were not updated because of errors:
        HEREDOC
        collection[:repos_with_update_errors].each do |error, paths|
          unless paths.empty?
            puts <<-HEREDOC

    #{error}:
    - #{paths.join("\n  - ")}
            HEREDOC
          end
        end
      end
      puts
    end

    def gem_desc_in_rakefile
      if File.exists?('Rakefile')
        desc = File.read('Rakefile')[/summary\s*=\s*\"(.*)\"/i, 1]
      else
        nil
      end
    end

    def gem_desc_in_config_hoe
      if File.exists?('config/hoe.rb')
        File.read('config/hoe.rb')[/summary\s*=\s*\"(.*)\"/i, 1]
      else
        nil
      end
    end

    def look_for_description
      desc = nil
      gemspec = Dir["*.gemspec"]
      unless gemspec.empty?
        desc = File.read(gemspec[0])[/summary\s*=\s*\"(.*)\"/i, 1]
        return desc
      end
      readme = Dir["*"].find_all {|p| p[/.*readme.*/i]}
      unless readme.empty?
        content = File.readlines(readme[0])
        if content.empty?
          desc = nil
        else
          desc = content[0].strip
          if desc.length > 60
            desc = desc[0,60].strip
            desc += " ..."
          end
        end
        return desc
      end
      desc
    end

    def git_command(dir, path, commands, collection, branch='master', options={})
      Dir.chdir File.expand_path(path) do
        response = `git checkout #{branch} 2>&1`
        commands.each do |command|
          response += `#{command} 2>&1`
        end
        desc = look_for_description
        unless options[:quiet]
          if response =~ /Already up-to-date|Current branch master is up to date/
            puts sprintf(PATH_FORMAT_STR, path, `git log -1 --pretty=format:"%cr"`, desc)
          else
            puts sprintf(PATH_FORMAT_STR, path, `git log -1 --pretty=format:"%cr"`, desc)
            puts "\n#{response}\n"
          end
        end
        if response =~/^(error:|fatal:)/
          puts <<-HEREDOC
  Error updating: #{path}

          HEREDOC
          collection[:repos_with_update_errors]["git error"] << path
        else
          collection[:repos] << [
            path,
            { :desc => desc,
              :updated_date => Time.rfc2822(`git log -1 --pretty=format:"%cD"`),
              :updated_relative => `git log -1 --pretty=format:"%cr"`,
              :updated_in_last_day => !`git log HEAD --no-merges --reverse --since='1 day'`.empty?,
              :updated_in_last_week => !`git log HEAD --no-merges --reverse --since='1 weeks'`.empty?,
              :updated_in_last_two_weeks => !`git log HEAD --no-merges --reverse --since='2 weeks'`.empty?,
              :commit_subject => `git log -1 --pretty=format:"%s %cn"`,
              :commit_author => `git log -1 --pretty=format:"%cn"` }
          ]
        end
      end
    end

  end
end
