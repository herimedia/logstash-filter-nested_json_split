# encoding: utf-8

require "logstash/filters/nested_json_split"
require "spec_helper"

describe LogStash::Filters::NestedJsonSplit do
  context "When using the default config" do
    config <<-CONFIG
      filter {
        nested_json_split {}
      }
    CONFIG

    describe "it should split \"events\" into \"message\"s" do
      sample({
        "events" => [
          "first event",
          "second event",
        ],
      }) do
        expect(subject.length).to eq(2)

        expect(subject[0]["message"]).to  eq("first event")
        expect(subject[1]["message"]).to  eq("second event")
      end
    end

    describe "it should retain the \"message\"s data structures" do
      sample({
        "events" => [
          "A String",
          2,
          { "A" => "Hash", "should" => "remain" },
          ["An", "Array"],
        ],
      }) do
        expect(subject.length).to eq(4)

        expect(subject[0]["message"]).to  eq("A String")
        expect(subject[1]["message"]).to  eq(2)
        expect(subject[2]["message"]).to  eq({ "A" => "Hash", "should" => "remain" })
        expect(subject[3]["message"]).to  eq(["An", "Array"])
      end
    end

    describe "it should discard the original \"events\"" do
      sample({
        "events" => ["event 1", "event 2"],
      }) do
        expect(subject.length).to eq(2)

        expect(subject[0]["events"]).to eq(nil)
        expect(subject[1]["events"]).to eq(nil)
      end
    end

    describe "it should retain the non-splitted key(s)" do
      sample({
        "events"  => ["event 1", "event 2"],
        "meta"    => "common meta data",
        "common"  => { "more" => ["common", "data"] },
      }) do
        expect(subject.length).to eq(2)

        expect(subject[0]["message"]).to  eq("event 1")
        expect(subject[0]["meta"]).to     eq("common meta data")
        expect(subject[0]["common"]).to   eq({ "more" => ["common", "data"] })

        expect(subject[1]["message"]).to  eq("event 2")
        expect(subject[1]["meta"]).to     eq("common meta data")
        expect(subject[1]["common"]).to   eq({ "more" => ["common", "data"] })
      end
    end

    describe "it should ignore empty event Arrays" do
      sample({
        "events" => [],
      }) do
        expect(subject).to eq(nil)
      end
    end

    describe "it should ignore empty event contents" do
      sample({
        "events" => ["event 1", "event 2", "", nil, [], {}],
      }) do
        expect(subject.length).to eq(2)
      end
    end

    it "should explode when \"events\" is not an Array" do
      event   = LogStash::Event.new("events" => "Not an Array")
      filter  = LogStash::Filters::NestedJsonSplit.new({})

      expect do
        filter.filter(event)
      end.to raise_error(LogStash::ConfigurationError)
    end
  end

  context "When using nested \"keys\"" do
    config <<-CONFIG
      filter {
        nested_json_split {
          keys => ["body", "events"]
        }
      }
    CONFIG

    describe "it should split \"events\" into \"message\"s" do
      sample({
        "body" => {
          "events" => [
            "first event",
            "second event",
          ],
        },
      }) do
        expect(subject.length).to eq(2)

        expect(subject[0]["message"]).to  eq("first event")
        expect(subject[1]["message"]).to  eq("second event")
      end
    end

    describe "it should discard the entire original top-level key" do
      sample({
        "body" => {
          "events" => ["event 1", "event 2"],
        },
      }) do
        expect(subject.length).to eq(2)

        expect(subject[0]["body"]).to eq(nil)
        expect(subject[1]["body"]).to eq(nil)
      end
    end

    describe "it should retain the non-splitted key(s)" do
      sample({
        "body" => {
          "events"  => ["event 1", "event 2"],
        },
        "meta"    => "common meta data",
        "common"  => { "more" => ["common", "data"] },
      }) do
        expect(subject.length).to eq(2)

        expect(subject[0]["message"]).to  eq("event 1")
        expect(subject[0]["meta"]).to     eq("common meta data")
        expect(subject[0]["common"]).to   eq({ "more" => ["common", "data"] })

        expect(subject[1]["message"]).to  eq("event 2")
        expect(subject[1]["meta"]).to     eq("common meta data")
        expect(subject[1]["common"]).to   eq({ "more" => ["common", "data"] })
      end
    end

    it "should explode when the the inner nesting is not a Hash" do
      event   = LogStash::Event.new("body" => "Not a Hash")
      filter  = LogStash::Filters::NestedJsonSplit.new("keys" => ["body", "events"])

      expect do
        filter.filter(event)
      end.to raise_error(LogStash::ConfigurationError)
    end
  end

  context "When using a custom \"target\"" do
    config <<-CONFIG
      filter {
        nested_json_split {
          target => "event"
        }
      }
    CONFIG

    describe "it should split \"events\" into the \"target\" instead of \"message\"" do
      sample({
        "events" => [
          "first event",
          "second event",
        ],
      }) do
        expect(subject.length).to eq(2)

        expect(subject[0]["event"]).to    eq("first event")
        expect(subject[0]["message"]).to  eq(nil)

        expect(subject[1]["event"]).to    eq("second event")
        expect(subject[1]["message"]).to  eq(nil)
      end
    end
  end
end
