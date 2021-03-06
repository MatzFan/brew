require "rubygems"

module Hbc
  module Source
    class PathBase
      # derived classes must define method self.me?

      def self.path_for_query(query)
        query_string = query.to_s
        Pathname.new(query_string.end_with?(".rb") ? query_string : query_string + ".rb")
      end

      attr_reader :path

      def initialize(path)
        @path = Pathname(path).expand_path
      end

      def load
        raise CaskError, "File '#{path}' does not exist"      unless path.exist?
        raise CaskError, "File '#{path}' is not readable"     unless path.readable?
        raise CaskError, "File '#{path}' is not a plain file" unless path.file?
        load_cask
      end

      def to_s
        # stringify to fully-resolved location
        path.to_s
      end

      private

      def load_cask
        instance_eval(cask_contents, __FILE__, __LINE__)
      rescue CaskError, StandardError, ScriptError => e
        # bug: e.message.concat doesn't work with CaskError exceptions
        raise e, e.message.concat(" while loading '#{path}'")
      end

      def cask_contents
        File.open(path, "rb") do |handle|
          contents = handle.read
          if defined?(Encoding)
            contents.force_encoding("UTF-8")
          else
            contents
          end
        end
      end

      def cask(header_token, &block)
        build_cask(Cask, header_token, &block)
      end

      def test_cask(header_token, &block)
        build_cask(TestCask, header_token, &block)
      end

      def build_cask(cask_class, header_token, &block)
        if header_token.is_a?(Hash)
          # Cask file is using old `cask :v1 => 'token'` syntax
          header_token = header_token.values.first
        end
        raise CaskTokenDoesNotMatchError.new(cask_token, header_token) unless cask_token == header_token
        cask_class.new(cask_token, sourcefile_path: path, &block)
      end

      def cask_token
        path.basename.to_s.sub(%r{\.rb}, "")
      end
    end
  end
end
