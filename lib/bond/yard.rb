require 'bond'
require 'yard'

module Bond
  # Adds class methods to Bond
  module Yard
    VERSION = '0.1.0'

    # Generates and loads completions for yardoc documented gems.
    # @param *gems Gem(s) with optional options hash at the end
    # @option *gems :verbose[Boolean] (false) Displays additional information when building yardoc.
    # @option *gems :reload[Boolean] (false) Rebuilds yard databases. Use when gems have changed versions.
    def load_yard_gems(*gems)
      Loader.load_yard_gems(*gems)
    end

    # Generates and loads completions for methods that take a hash of options and have been
    # documented with @option.
    module Loader
      extend self

      def load_yard_gems(*gems)
        @options = gems[-1].is_a?(Hash) ? gems.pop : {}
        gems.select {|e| load_yard_gem(e) }
      end

      def load_yard_gem(rubygem)
        raise("Unable to find gem.") unless (yardoc = find_yardoc(rubygem))
        completion_file = File.join(dir('yard_completions'), rubygem+'.rb')
        create_completion_file(yardoc, completion_file) if !File.exists?(completion_file) || @options[:reload]
        M.load_file completion_file
      rescue
        $stderr.puts "Bond Error: Didn't load yard completions for gem '#{rubygem}'. #{$!.message}"
      end

      def create_completion_file(yardoc, completion_file)
        YARD::Registry.load!(yardoc)
        methods_hash = find_methods_with_options
        body = generate_method_completions(methods_hash)
        File.open(completion_file, 'w') {|e| e.write body }
      end

      def find_yardoc(rubygem)
        (file = YARD::Registry.yardoc_file_for_gem(rubygem) rescue nil) and return(file)
        if (file = M.find_gem_file(rubygem, rubygem+'.rb'))
          output_dir = File.join(dir('.yardocs'), rubygem)
          cmd = ['yardoc', '-n', '-b', output_dir]
          cmd << '-q' unless @options[:verbose]
          cmd += ['-c', output_dir] unless @options[:reload]
          cmd += [file, File.expand_path(file+'/..')+"/#{rubygem}/**/*.rb"]
          puts "Bond: "+cmd.join(' ') if @options[:verbose]
          puts "Bond: Building/loading #{rubygem}'s .yardoc database ..."
          system *cmd
          output_dir
        end
      end

      def dir(subdir)
        (@dirs ||= {})[subdir] ||= begin
          require 'fileutils'
          FileUtils.mkdir_p File.join(M.home, '.bond', subdir)
          File.join(M.home, '.bond', subdir)
        end
      end

      def find_methods_with_options
        YARD::Registry.all(:method).inject({}) {|a,m|
          opts = m.tags.select {|e| e.is_a?(YARD::Tags::OptionTag) }.map {|e| e.pair.name }
          a[m.path] = opts if !opts.empty? && m.path
          a
        }
      end

      def generate_method_completions(methods_hash)
        methods_hash.map do |meth, options|
          options.map! {|e| e.sub(/^:/, '') }
          meth = meth.sub(/#initialize$/, '.new')
          %Q[complete(:method=>'#{meth}') {\n  #{options.inspect}\n}]
        end.join("\n")
      end
    end
  end
end

Bond.extend Bond::Yard
