# frozen_string_literal: true

module RubyLLM
  module MCP
    # Turns a configured sampling model into the two things sampling needs: the
    # arguments for a RubyLLM::Chat, and the model name to report back to the
    # server.
    #
    # A plain String still works and names the model on its own. A Hash passes
    # its keys to RubyLLM::Chat, which is how you reach the +provider:+,
    # +protocol:+, and +assume_model_exists:+ keywords RubyLLM 2.0 uses to
    # resolve a model:
    #
    #   config.sampling.preferred_model = { model: "gpt-4.1", provider: :openai }
    #
    module SamplingModel
      module_function

      # @param model [String, Symbol, Hash] the configured sampling model
      # @return [RubyLLM::Chat]
      def chat(model)
        RubyLLM::Chat.new(**chat_options(model))
      end

      # @return [Hash] keyword arguments for RubyLLM::Chat
      def chat_options(model)
        return { model: model } unless model.is_a?(Hash)

        model.to_h.transform_keys(&:to_sym)
      end

      # The model name the MCP server is told about.
      # @return [String, nil]
      def name(model)
        return model&.to_s unless model.is_a?(Hash)

        chat_options(model)[:model]&.to_s
      end
    end
  end
end
