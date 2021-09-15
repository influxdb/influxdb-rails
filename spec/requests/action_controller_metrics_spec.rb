require "#{File.dirname(__FILE__)}/../spec_helper"

RSpec.describe "ActionController metrics", type: :request do
  let(:tags_middleware) do
    lambda do |tags|
      tags.merge(tags_middleware: :tags_middleware)
    end
  end
  before do
    allow_any_instance_of(ActionDispatch::Request).to receive(:request_id).and_return(:request_id)
    allow_any_instance_of(InfluxDB::Rails::Configuration).to receive(:application_name).and_return(:app_name)
    allow_any_instance_of(InfluxDB::Rails::Configuration).to receive(:tags_middleware).and_return(tags_middleware)
  end

  it "writes metric" do
    get "/metrics"

    expect_metric(
      name:   "rails",
      tags:   a_hash_including(
        hook:        "process_action",
        status:      200,
        format:      :html,
        http_method: "GET"
      ),
      values: a_hash_including(
        view:       be_between(1, 500),
        db:         be_between(1, 500),
        controller: be_between(1, 500)
      )
    )
  end

  it "writes default and custom tags" do
    get "/metrics"

    expect_metric(
      name:   "rails",
      tags:   a_hash_including(
        hook:            "process_action",
        location:        "MetricsController#index",
        additional_tag:  :value,
        server:          Socket.gethostname,
        app_name:        :app_name,
        tags_middleware: :tags_middleware
      ),
      values: a_hash_including(
        additional_value: :value,
        request_id:       :request_id
      )
    )
  end

  it "includes correct timestamps" do
    travel_to Time.zone.local(2018, 1, 1, 9, 0, 0)

    get "/metrics"

    expect_metric(
      name:      "rails",
      tags:      a_hash_including(
        method: "MetricsController#index",
        hook:   "process_action"
      ),
      values:    a_hash_including(
        started: 1_514_797_200
      ),
      timestamp: 1_514_797_200
    )
  end

  it "does not write metric when hook is ignored" do
    allow_any_instance_of(InfluxDB::Rails::Configuration).to receive(:ignored_hooks).and_return(["process_action.action_controller"])

    get "/metrics"

    expect_no_metric(
      tags: a_hash_including(
        method: "MetricsController#index",
        hook:   "process_action"
      )
    )
  end

  it "does not crash when controller throws and exception" do
    get "/exceptions"

    expect_metric(
      tags: a_hash_including(
        method:    "ExceptionsController#index",
        hook:      "process_action",
        exception: "ActiveRecord::RecordNotFound",
        status:    404
      )
    )
  end
end
