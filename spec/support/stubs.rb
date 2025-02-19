# frozen_string_literal: true

require 'json'

module Stubs
  def stub_download(req, resp, params = {})
    set_stub(req, resp, params.merge({ default_status: 200, postfix: 'download' }))
  end

  def stub_process_check(req, resp, process_id, params = {})
    set_stub(req, resp, params.merge({ default_status: 200, postfix: process_id, endpoint: 'processes', method: :get }))
  end

  def stub_download_async(req, resp, params = {})
    set_stub(req, resp, params.merge({ default_status: 200, postfix: 'async-download' }))
  end

  def stub_upload(req, resp, params = {})
    set_stub(req, resp, params.merge({ default_status: 202, postfix: 'upload' }))
  end

  private

  def set_stub(req, resp, params)
    project_id = params[:project_id] || ENV.fetch('LOKALISE_PROJECT_ID', nil)
    endpoint = params.fetch(:endpoint, 'files')

    stub_request(
      params.fetch(:method, :post),
      "https://api.lokalise.com/api2/projects/#{project_id}/#{endpoint}/#{params[:postfix]}"
    ).with(
      request_params(req)
    ).to_return(
      response_params(resp, params.fetch(:status, params[:default_status]))
    )
  end

  def request_params(req)
    req_params = {
      headers: {
        'Accept' => 'application/json',
        'Accept-Encoding' => 'gzip,deflate,br',
        'User-Agent' => "ruby-lokalise-api gem/#{RubyLokaliseApi::VERSION}",
        'X-Api-Token' => ENV.fetch('LOKALISE_API_TOKEN', nil)
      }
    }

    req_params = req_params.merge({ body: JSON.dump(req) }) if req

    req_params
  end

  def response_params(resp, status)
    body = File.read File.join(fixture_path, resp)

    {
      status: status,
      body: body
    }
  end

  def fixture_path
    File.expand_path('../fixtures', __dir__)
  end
end
