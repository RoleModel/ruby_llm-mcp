---
layout: default
title: Upgrading from 1.0 to 2.0
parent: Advanced
nav_order: 13
description: "Guide for upgrading from RubyLLM MCP 1.0 to 2.0"
nav_exclude: true
---

# Upgrading from 1.0 to 2.0
{: .no_toc }

Version 2.0 moves to RubyLLM 2.0. Most of the change is in how tool results and
message content are shaped, because RubyLLM 2.0 removed `RubyLLM::Content` and
now keeps message text and attachments apart.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Breaking Changes

{: .label .label-red }
Breaking Change

### 1. RubyLLM 2.0 is required

```ruby
gem 'ruby_llm', '~> 2.0'
gem 'ruby_llm-mcp', '~> 2.0'
```

```bash
bundle update ruby_llm ruby_llm-mcp
```

Read the [RubyLLM upgrade guide](https://rubyllm.com/upgrading/) as well. It
covers the renames in RubyLLM itself, which apply to any of your own code that
talks to RubyLLM directly.

### 2. Tool results are text, or text plus attachments

`RubyLLM::MCP::Tool#execute` used to return a `RubyLLM::MCP::Content`. It now
returns what RubyLLM 2.0 tools return: a `String`, or an `Array` holding the
text followed by attachments when the server sent an image, audio, or binary
resource.

Before:

```ruby
result = tool.execute(filename: "report.txt")

result.to_s              # text
result.attachments.first # RubyLLM::MCP::Attachment
```

After:

```ruby
result = tool.execute(filename: "report.txt")

case result
when String
  result                                   # text
when Array
  text, *attachments = result
end
```

An error is still a Hash, as before:

```ruby
{ error: "Tool execution error: ..." }
```

### 3. `RubyLLM::MCP::Content` is a value object

`Content` no longer subclasses `RubyLLM::Content`, which RubyLLM 2.0 removed. It
is now a small object holding `text` and `attachments`, with three ways out:

```ruby
content.text            # String or nil
content.attachments     # Array<RubyLLM::MCP::Attachment>
content.to_llm_result   # what a tool returns: String, or [text, *attachments]
content.to_message      # a RubyLLM::Message
```

`Resource#to_content` still returns a `Content`, so resource code is unaffected
unless it passed that `Content` straight to RubyLLM. Build a message instead:

```ruby
chat.add_message(resource.to_content.to_message)
```

`Resource#include(chat)` already does this for you.

### 4. `Tool#params_schema` is now `Tool#parameters_schema`

RubyLLM 2.0 renamed the reader. `Tool#to_h` uses the new key too.

```ruby
tool.parameters_schema # was tool.params_schema
```

### 5. `RubyLLM::MCP::Attachment` decodes its payload

`Attachment#content` now returns the raw bytes. The base64 payload the server
sent is on `Attachment#encoded`, unchanged and not re-encoded.

```ruby
attachment.encoded   # base64, as MCP sent it
attachment.content   # decoded bytes
attachment.mime_type # what the server reported
```

---

## New in 2.0

### Sampling models accept chat options

`config.sampling.preferred_model` still takes a model name. It now also takes a
Hash, whose keys go to `RubyLLM::Chat.new`. This is how you pin a provider,
choose a wire protocol, or name a model RubyLLM's registry does not list —
all of which matter more under RubyLLM 2.0, which resolves models more strictly
and defaults OpenAI to the Responses API.

```ruby
RubyLLM::MCP.configure do |config|
  config.sampling.enabled = true

  config.sampling.preferred_model = {
    model: "gpt-4.1",
    provider: :openai,
    protocol: :chat_completions
  }
end
```

The server is still told the plain model name. A block form works the same way
and may return either a String or a Hash.

---

## Upgrade Checklist

1. Update `ruby_llm` to `~> 2.0` and `ruby_llm-mcp` to `~> 2.0`.
2. Find every `tool.execute` call and handle a `String`/`Array` result.
3. Rename `params_schema` to `parameters_schema`.
4. Replace any `RubyLLM::MCP::Content` passed to RubyLLM with `to_message` or
   `to_llm_result`.
5. If you read `Attachment#content` expecting base64, switch to `#encoded`.
6. If sampling picks a model RubyLLM cannot resolve on the name alone, give
   `preferred_model` a Hash with `provider:`.

## Resources

- **[RubyLLM 2.0 upgrade guide](https://rubyllm.com/upgrading/)**
- **[Sampling]({% link client/sampling.md %})** - Model selection and handlers
- **[Adapters & Transports]({% link guides/adapters.md %})**

**Questions?** [Open an issue](https://github.com/patvice/ruby_llm-mcp/issues) or check the [documentation]({% link index.md %}).
