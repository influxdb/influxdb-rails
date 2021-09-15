require "action_controller/railtie"
require "active_record/railtie"
require "active_job"
require "action_mailer"

app = Class.new(Rails::Application)
app.config.secret_key_base = "1234567890abcdef1234567890abcdef"
app.config.secret_token = "1234567890abcdef1234567890abcdef"
app.config.session_store :cookie_store, key: "_myapp_session"
app.config.active_support.deprecation = :log
app.config.eager_load = false
app.config.root = __dir__
Rails.backtrace_cleaner.remove_silencers!
ActiveJob::Base.logger = Rails.logger
ActionMailer::Base.delivery_method = :test
app.initialize!

app.routes.draw do
  resources :metrics, only: %i[index show]
  resources :exceptions, only: :index
end

ENV["DATABASE_URL"] = "sqlite3::memory:"
ActiveRecord::Schema.define do
  create_table :metrics, force: true do |t|
    t.string :name

    t.timestamps
  end
end

class MetricJob < ActiveJob::Base
  queue_as :default

  def perform
    # Do something later
  end
end

class MetricMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"

  def welcome_mail
    mail(to: "eisendieter@werder.de", subject: "Welcome to metrics!") do |format|
      format.text { render plain: "Hello Dieter!" }
    end
  end
end

class Metric < ActiveRecord::Base; end

class ApplicationController < ActionController::Base; end

class MetricsController < ApplicationController
  prepend_view_path File.join(__dir__, "..", "views")

  before_action do
    InfluxDB::Rails.current.values = { additional_value: :value }
    InfluxDB::Rails.current.tags = { additional_tag: :value }
  end

  def index
    InfluxDB::Rails.instrument "name", tags: { block_tag: :block_tag }, values: { block_value: :block_value } do
      1 + 1
    end
    MetricJob.perform_later
    MetricMailer.with(user: "eisendieter").welcome_mail.deliver_now
    Metric.create!(name: "name")
  end

  def show
    @metric = Metric.find_by(name: "name")
  end
end

class ExceptionsController < ApplicationController
  def index
    raise ActiveRecord::RecordNotFound
  end
end

Object.const_set(:ApplicationHelper, Module.new)
