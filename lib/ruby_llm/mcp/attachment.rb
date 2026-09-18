# frozen_string_literal: true

require "base64"
require "stringio"

module RubyLLM
  module MCP
    # An attachment built from the base64 payload MCP servers send for image,
    # audio, and blob resource content. The MIME type comes from the server
    # rather than from sniffing the bytes.
    class Attachment < RubyLLM::Attachment
      # Used when a server sends content without saying what it is.
      DEFAULT_MIME_TYPE = "application/octet-stream"

      # The base64 payload the server sent, returned without re-encoding it.
      attr_reader :encoded

      # @param data [String] base64 encoded bytes, as MCP sends them
      # @param mime_type [String] the MIME type the server reported
      # @param filename [String, nil] name to show the model, derived from the
      #   MIME type when omitted
      def initialize(data, mime_type, filename: nil)
        @encoded = data.to_s
        @mime_type = mime_type.to_s.empty? ? DEFAULT_MIME_TYPE : mime_type
        super(StringIO.new(decoded_bytes), filename: filename || default_filename)
      end

      private

      def decoded_bytes
        Base64.decode64(@encoded)
      end

      def default_filename
        return "attachment" if @mime_type == DEFAULT_MIME_TYPE

        "attachment.#{format}"
      end

      # The MIME type is authoritative here, so keep what the server reported
      # instead of sniffing the source.
      def determine_mime_type
        @mime_type
      end
    end
  end
end
