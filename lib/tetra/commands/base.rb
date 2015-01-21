# encoding: UTF-8

module Tetra
  # implements common options and utility methods
  class BaseCommand < Clamp::Command
    include Logging

    # Options available to all tetra commands
    option %w(-v --verbose), :flag, "verbose output"
    option ["--very-verbose"], :flag, "very verbose output"
    option ["--very-very-verbose"], :flag, "very very verbose output"

    # verbosity handlers
    def very_very_verbose=(flag)
      configure_log_level(verbose?, very_verbose?, flag)
    end

    def very_verbose=(flag)
      configure_log_level(verbose?, flag, very_very_verbose?)
    end

    def verbose=(flag)
      configure_log_level(flag, very_verbose?, very_very_verbose?)
    end

    # maps verbosity options to log level
    def configure_log_level(v, vv, vvv)
      if vvv
        log.level = ::Logger::DEBUG
      elsif vv
        log.level = ::Logger::INFO
      elsif v
        log.level = ::Logger::WARN
      else
        log.level = ::Logger::ERROR
      end
    end

    # prints an error message and exits unless there is a dry-run in progress
    def ensure_dry_running(state, project)
      if project.dry_running? == state
        yield
      else
        if state == true
          puts "Please start a dry-run first, use \"tetra dry-run start\""
        else
          puts "Please finish or abort this dry-run first, use \"tetra dry-run finish\" or \"tetra dry-run abort\""
        end
      end
    end

    # outputs output of a file generation
    def print_generation_result(project, result_path, conflict_count = 0)
      puts "#{format_path(result_path, project)} generated"
      puts "Warning: #{conflict_count} unresolved conflicts" if conflict_count > 0
    end

    # generates a version of path relative to the current directory
    def format_path(path, project)
      full_path = (
        if Pathname.new(path).relative?
          File.join(project.full_path, path)
        else
          path
        end
      )
      Pathname.new(full_path).relative_path_from(Pathname.new(Dir.pwd))
    end

    # handles most fatal exceptions
    def checking_exceptions
      yield
    rescue Errno::EACCES => e
      $stderr.puts e
    rescue Errno::ENOENT => e
      $stderr.puts e
    rescue Errno::EEXIST => e
      $stderr.puts e
    rescue NoProjectDirectoryError => e
      $stderr.puts "#{e.directory} is not a tetra project directory, see tetra init"
    rescue GitAlreadyInitedError
      $stderr.puts "This directory is already a tetra project"
    rescue ExecutableNotFoundError => e
      $stderr.puts "Executable #{e.executable} not found in kit/ or any of its subdirectories"
    rescue ExecutionFailed => e
      $stderr.puts "Failed to run `#{e.commandline}` (exit status #{e.status})"
    rescue Interrupt
      $stderr.puts "Execution interrupted by the user"
    end
  end
end
