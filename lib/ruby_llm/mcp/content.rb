# frozen_string_literal: true

module RubyLLM
  module MCP
    # Text and attachments returned by an MCP server, held together until they
    # are handed to RubyLLM, which keeps the two apart.
    class Content
      attr_reader :text, :attachments

      def initialize(text: nil, attachments: nil)
        @text = text
        @attachments = Array(attachments)
      end

      # The value a RubyLLM::Tool#execute returns: a String on its own, or the
      # text followed by the attachments when there are any.
      def to_llm_result
        return text.to_s if attachments.empty?

        [text.to_s, *attachments]
      end

      def to_message(role: "user")
        RubyLLM::Message.new(
          role: role,
          content: text.to_s,
          attachments: attachments
        )
      end

      def to_s
        text.to_s
      end
    end
  end
end
