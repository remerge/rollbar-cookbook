default_action :notify

property :path, String, name_attribute: true
property :token, String, required: true
property :env, String, required: true
property :revision, String
property :comment, String
property :command, String

require 'uri'
require 'net/http'

action :notify do
  if new_resource.revision
    revision = new_resource.revision
  elsif new_resource.command
    revision = %x(#{new_resource.command}).chomp
  elsif new_resource.path
    Dir.chdir(new_resource.path) do
      revision = %x(git log -n 1 --pretty=format:"%H").chomp
    end
  else
    raise "a revision, path or command should be provided"
  end

  payload = {
    "access_token" => new_resource.token,
    "environment" => new_resource.env,
    "local_username" => node[:fqdn],
    "revision" => revision
  }

  payload["comment"] = new_resource.comment if new_resource.comment

  uri = URI(node[:rollbar][:endpoint])
  res = nil

  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
    req = Net::HTTP::Post.new(uri.request_uri)
    req.form_data = payload
    res = http.request(req)
  end
end
