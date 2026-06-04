control 'rubygems' do
  describe directory('/opt/rubygems.cinc.sh') do
    it { should exist }
  end

  describe directory('/data/rubygems.cinc.sh') do
    it { should exist }
  end

  describe file('/opt/rubygems.cinc.sh/compose.yml') do
    it { should exist }
  end

  describe file('/opt/rubygems.cinc.sh/nginx.conf') do
    it { should exist }
  end

  describe file('/opt/rubygems.cinc.sh/.env') do
    it { should exist }
    its('mode') { should cmp '0400' }
    its('content') { should match(/^API_KEYS=/) }
  end

  # The API_KEYS value must be a JSON object (or empty). Parse the value
  # rendered into the .env to confirm the cookbook produced valid JSON.
  describe 'API_KEYS env value' do
    api_keys = file('/opt/rubygems.cinc.sh/.env').content.to_s[/^API_KEYS=(.*)$/, 1].to_s
    it 'is empty or valid JSON' do
      next if api_keys.empty?
      expect { JSON.parse(api_keys) }.not_to raise_error
      expect(JSON.parse(api_keys)).to be_a(Hash)
    end
  end

  %w(geminabox nginx).each do |svc|
    describe json(content: command("docker compose -p rubygems-cinc-sh -f /opt/rubygems.cinc.sh/compose.yml ps #{svc} --format json").stdout) do
      its(%w(State)) { should eq 'running' }
    end
  end

  describe http('http://127.0.0.1:8080') do
    its('status') { should eq 200 }
    its('body') { should match(/Cinc RubyGems/) }
  end
end
