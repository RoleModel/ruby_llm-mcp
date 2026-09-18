# frozen_string_literal: true

module RubyLLM
  module MCP
    module Native
      module Messages
        # Response message builders
        # Responses are sent in reply to requests from the server
        module Responses
          extend Helpers

          module_function

          def ping(id:)
            {
              jsonrpc: JSONRPC_VERSION,
              id: id,
              result: {}
            }
          end

          def roots_list(id:, roots_paths:)
            roots_response = roots_paths.map do |path|
              {
                uri: "file://#{path}",
                name: File.basename(path, ".*")
              }
            end

            {
              jsonrpc: JSONRPC_VERSION,
              id: id,
              result: {
                roots: roots_response
              }
            }
          end

          def result(id:, value:)
            {
              jsonrpc: JSONRPC_VERSION,
              id: id,
              result: value
            }
          end

          def sampling_create_message(id:, message:, model:)
            {
              jsonrpc: JSONRPC_VERSION,
              id: id,
              result: {
                role: message.role,
                content: format_content(message),
                model: model,
                stopReason: format_stop_reason(message)
              }
            }
          end

          def elicitation(id:, action:, content: nil)
            {
              jsonrpc: JSONRPC_VERSION,
              id: id,
              result: {
                action: action,
                content: content
              }.compact
            }
          end

          def error(id:, message:, code: JsonRpc::ErrorCodes::SERVER_ERROR, data: nil)
            error_object = {
              code: code,
              message: message
            }
            error_object[:data] = data if data

            {
              jsonrpc: JSONRPC_VERSION,
              id: id,
              error: error_object
            }
          end

          # RubyLLM keeps message text and attachments apart, so an image or
          # audio reply arrives as an empty body with one attachment.
          def format_content(message)
            text = message.content.to_s
            attachment = Array(message.attachments).first if message.respond_to?(:attachments)

            if text.empty? && attachment
              { type: attachment.type.to_s, data: attachment.encoded, mimeType: attachment.mime_type }
            else
              { type: "text", text: text }
            end
          end
          private_class_method :format_content

          # MCP names its stop reasons in camelCase. Handlers may hand back an
          # object with its own stop_reason; RubyLLM messages carry a
          # finish_reason symbol instead.
          def format_stop_reason(message)
            reason = message.stop_reason if message.respond_to?(:stop_reason)
            reason ||= message.finish_reason if message.respond_to?(:finish_reason)

            reason ? snake_to_camel(reason.to_s) : "endTurn"
          end
          private_class_method :format_stop_reason

          def snake_to_camel(str)
            parts = str.split("_")
            parts.first + parts[1..].map(&:capitalize).join
          end
          private_class_method :snake_to_camel
        end
      end
    end
  end
end
