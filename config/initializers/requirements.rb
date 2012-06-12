$:.unshift Rails.root.join("lib", "freight_train", "lib").to_s
$:.unshift Rails.root.join("lib", "lail_extensions", "lib").to_s
$:.unshift Rails.root.join("lib", "unfuddle", "lib").to_s

require 'freight_train'
require 'lail/core_extensions'
require 'unfuddle'
require 'grit_patch'



require 'unfuddle/neq'

include Unfuddle::NeqHelper

Rails.application.config.queues = [ {
  
    # !todo: add "severity-eq-0" to OR
    #
    #   title:      "To Proofread",
    #   conditions: [ [ "#{f "Health"}-eq-0",
    #                   "#{f "Health"}-eq-#{v "Health", "Summary and Description need work"}",
    #                   "#{f "Health"}-eq-#{v "Health", "Summary needs work"}",
    #                   "severity-eq-0" ],
    #                 [ "status-neq-closed" ] ],
    #
    name: "To Proofread",
    slug: "assign_health",
    description: "<b>Testers</b>, check that these tickets are healthy and unique.",
    query: {"Health" => [0, "Summary and Description need work", "Summary needs work"], :status => neq(:closed)}
  }, {
    name: "To Accept",
    slug: "new_tickets",
    description: "<b>Developers</b>, check that these tickets make sense and accept them.",
    query: {:status => :new, :severity => neq(0), :severity => neq("0 Suggestion"), "Health" => ["Good", "Description needs work"]}
  }, {
    name: "Flagged",
    slug: "staged_for_development",
    description: "Tickets flagged for forthcoming work",
    query: :local
  }, {
    name: "In Development",
    slug: "in_development",
    description: "Tickets currently being worked on",
    query: {"Deployment" => "In Development", :status => :accepted}
  }, {
    name: "Queued",
    slug: "staged_for_testing",
    description: "Tickets waiting to enter testing",
    query: {"Deployment" => "In Development", :status => :resolved}
  }, {
    name: "In Testing (PRI)",
    slug: "in_testing",
    description: "<b>Testers</b>, these tickets are ready to test <u>in PRI</u>",
    query: {"Deployment" => "In Testing (PRI)", :status => :resolved}
  }, {
    name: "In Testing (Production)",
    slug: "in_testing_production",
    description: "<b>Testers</b>, these tickets are ready to test <u>in Production</u>",
    query: {"Deployment" => "In Production (Released)", :status => :resolved}
  # }, {
  #   name: "Ready to Release",
  #   slug: "staged_for_release",
  #   description: "Tickets staged for the next release",
  #   query: {"Deployment" => neq("In Production (Released)"), :status => :closed, :resolution => :fixed}
} ]
