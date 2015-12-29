Gem::Specification.new do |s|
  s.authors         = ["Niels Ganser <niels@herimedia.com>"]
  s.description     = "This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/plugin install gemname. This gem is not a stand-alone program."
  s.email           = "niels@herimedia.com"
  s.files           = Dir[
    "*.gemspec",
    "*.md",
    "Gemfile",
    "LICENSE",
    "lib/**/*",
    "spec/**/*",
  ]
  s.homepage        = "http://www.elastic.co/guide/en/logstash/current/index.html"
  s.licenses        = ["Apache License (2.0)"]
  s.metadata        = { "logstash_plugin" => "true", "logstash_group" => "filter" }
  s.name            = "logstash-filter-nested_json_split"
  s.require_paths   = ["lib"]
  s.summary         = "This nested_json_split filter splits an Array in a nested Hash / JSON object into multiple individual events."
  s.test_files      = s.files.grep(%r{\Aspec/})
  s.version         = "0.9.1"

  s.cert_chain      = ["certs/gems.herimedia.com-CA.pem", "certs/niels@herimedia.com.crt"]
  s.signing_key     = File.expand_path(ENV["SIGNING_KEY"]) if $0 =~ /gem\z/

  s.add_development_dependency  "logstash-devutils"
  s.add_runtime_dependency      "logstash-core", ">= 2.0.0", "< 3.0.0"
end
