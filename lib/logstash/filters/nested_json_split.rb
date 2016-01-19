# encoding: utf-8

require "logstash/filters/base"
require "logstash/namespace"

# This plugin ingests a (potentially nested) JSON object and splits it into
# multiple events based on one of its attributes that is an Array.
#
# For example, you could turn this aggregate event:
#
# [source,ruby]
# ----------------------------------------------------------------------------
# {
#   "requestId": "123",
#   "body": {
#     "events": [
#       { "id": "456", "master_event": "First event." },
#       { "id": "789", "master_event": "Second event." },
#     }
#   }
# }
# ----------------------------------------------------------------------------
#
# Into these individual events:
#
# [source,ruby]
# ----------------------------------------------------------------------------
# {
#   "requestId": "123",
#   "event": { "id": "456", "master_event": "First event." }
# }
#
# {
#   "requestId": "123",
#   "event": { "id": "789", "master_event": "Second event." }
# }
# ----------------------------------------------------------------------------
#
# By configuring the plugin like so:
#
# [source]
# ----------------------------------------------------------------------------
# filter {
#   nested_json_split {
#     keys:   ["body", "events"]
#     target: "event"
#   }
# }
# ----------------------------------------------------------------------------
#
# By default, the following configuration is applied:
#
# [source]
# ----------------------------------------------------------------------------
# filter {
#   nested_json_split {
#     keys:   ["events"]
#     target: "message"
#   }
# }
# ----------------------------------------------------------------------------
class LogStash::Filters::NestedJsonSplit < LogStash::Filters::Base

  config_name "nested_json_split"

  config :keys,   validate: :array,   default: ["events"]
  config :target, validate: :string,  default: "message"

  def filter(master_event)
    events = master_event.remove(@keys.first)
    @keys[1..-1].each do |key|
      return abort_splitting!(
        master_event,
        "Input must be a JSON object / Ruby Hash but is instead: #{events.class.name}.",
         events:  events,
         key:     key,
        ) unless events.is_a?(Hash)

      events = events[key]
    end

    if events.nil?
      @logger.warn("Filtered events are null", events: events, keys: @keys, master_event: master_event, target: @target)
    elsif not events.is_a?(Array)
      return abort_splitting!(
        master_event,
        "Filtered input should be an Array but is instead: #{events.class.name} (#{events.inspect}).",
         events:  events,
        )
    elsif events.empty?
      @logger.info("Filtered events are empty", events: events, keys: @keys, master_event: master_event, target: @target)
    else
      events.each_with_index do |event_payload, idx|
        if event_payload.respond_to?(:empty?) ? event_payload.empty? : !event_payload
          @logger.info("Event #{idx+1} is empty", event_payload: event_payload, events: events, keys: @keys, master_event: master_event, target: @target)
        else
          event = master_event.clone
          event[@target] = event_payload

          @logger.debug("Stashing event #{idx+1}", event: event, event_payload: event_payload, events: events, keys: @keys, master_event: master_event, target: @target)

          filter_matched(event)
          yield event
        end
      end
    end

    finalize(master_event)
  end

  def register
    raise LogStash::ConfigurationError, "\"keys\" must be an Array of Strings but is: #{@keys.inspect}." unless @keys.is_a?(Array) and @keys.all? { |k| k.is_a?(String) }
  end

  protected

  def abort_splitting!(master_event, reason, debug_params = {})
    @logger.error(reason, {
      keys:         @keys,
      master_event: master_event,
      target:       @target,
    }.merge(debug_params))

    finalize(master_event)
  end

  def finalize(master_event)
    master_event.cancel
    filter_matched(master_event)
  end

end
