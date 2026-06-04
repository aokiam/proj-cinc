#
# Cookbook:: proj-cinc
# Recipe:: rubygems
#
# Copyright:: 2025-2026, Oregon State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'osl-docker'
include_recipe 'osl-firewall'
include_recipe 'osl-git'

rubygems_secrets = data_bag_item('proj-cinc', 'rubygems')

rubygems_dir = '/opt/rubygems.cinc.sh'

directory '/data/rubygems.cinc.sh' do
  recursive true
end

git rubygems_dir do
  repository 'https://gitlab.com/cinc-project/rubygems.cinc.sh.git'
  revision 'main'
  notifies :rebuild, 'osl_dockercompose[rubygems-cinc-sh]'
end

template "#{rubygems_dir}/.env" do
  source 'rubygems.env.erb'
  mode '0400'
  sensitive true
  variables(
    api_key: rubygems_secrets['api_key'],
    api_keys: rubygems_secrets['api_keys'] || '',
    admin_user: rubygems_secrets['admin_user'],
    admin_password: rubygems_secrets['admin_password'],
    gem_dir: '/data/rubygems.cinc.sh'
  )
  notifies :rebuild, 'osl_dockercompose[rubygems-cinc-sh]'
end

docker_image 'cincproject/rubygems-cinc-sh' do
  tag 'latest'
  notifies :rebuild, 'osl_dockercompose[rubygems-cinc-sh]'
end

osl_dockercompose 'rubygems-cinc-sh' do
  directory rubygems_dir
  config_files %w(compose.yml)
end

osl_firewall_port 'cinc-rubygems' do
  service_name 'http'
  ports %w(8080)
  osl_only true
end
