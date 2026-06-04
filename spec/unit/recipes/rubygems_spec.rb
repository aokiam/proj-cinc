require_relative '../../spec_helper'

describe 'proj-cinc::rubygems' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p) do |_node|
          stub_data_bag_item('proj-cinc', 'rubygems').and_return(
            'id' => 'rubygems',
            'api_key' => 'test_api_key',
            'api_keys' => '{"projectb-test-key":["projectb","projectb-plugin"]}',
            'admin_user' => 'test_admin',
            'admin_password' => 'test_password'
          )
          stub_command('iptables -C INPUT -j REJECT --reject-with icmp-host-prohibited 2>/dev/null').and_return(false)
        end.converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it { is_expected.to include_recipe('osl-docker') }
      it { is_expected.to include_recipe('osl-firewall') }
      it { is_expected.to include_recipe('osl-git') }

      it do
        is_expected.to create_directory('/data/rubygems.cinc.sh').with(recursive: true)
      end

      it do
        is_expected.to sync_git('/opt/rubygems.cinc.sh').with(
          repository: 'https://gitlab.com/cinc-project/rubygems.cinc.sh.git',
          revision: 'main'
        )
      end

      it do
        expect(chef_run.git('/opt/rubygems.cinc.sh')).to \
          notify('osl_dockercompose[rubygems-cinc-sh]').to(:rebuild)
      end

      it do
        is_expected.to create_template('/opt/rubygems.cinc.sh/.env').with(
          source: 'rubygems.env.erb',
          mode: '0400',
          sensitive: true
        )
      end

      it do
        expect(chef_run).to render_file('/opt/rubygems.cinc.sh/.env')
          .with_content('API_KEY=test_api_key')
          .with_content('API_KEYS={"projectb-test-key":["projectb","projectb-plugin"]}')
      end

      it do
        expect(chef_run.template('/opt/rubygems.cinc.sh/.env')).to \
          notify('osl_dockercompose[rubygems-cinc-sh]').to(:rebuild)
      end

      it do
        is_expected.to pull_docker_image('cincproject/rubygems-cinc-sh').with(
          tag: 'latest'
        )
      end

      it do
        expect(chef_run.docker_image('cincproject/rubygems-cinc-sh')).to \
          notify('osl_dockercompose[rubygems-cinc-sh]').to(:rebuild)
      end

      it do
        is_expected.to up_osl_dockercompose('rubygems-cinc-sh').with(
          directory: '/opt/rubygems.cinc.sh',
          config_files: %w(compose.yml)
        )
      end

      it do
        is_expected.to accept_osl_firewall_port('cinc-rubygems').with(
          service_name: 'http',
          ports: %w(8080),
          osl_only: true
        )
      end
    end
  end
end
