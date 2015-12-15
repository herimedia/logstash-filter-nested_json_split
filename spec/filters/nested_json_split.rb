# encoding: utf-8
require 'spec_helper'
require "logstash/filters/nested_json_split"

describe LogStash::Filters::NestedJsonSplit do
  describe "Set to Hello World" do
    let(:config) do <<-CONFIG
      filter {
        nested_json_split {
          message => "Hello World"
        }
      }
    CONFIG
    end

    sample("message" => "some text") do
      expect(subject).to include("message")
      expect(subject['message']).to eq('Hello World')
    end
  end
end
