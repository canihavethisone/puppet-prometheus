# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'prometheus postfix exporter', if: host_inventory['facter']['os']['name'] != 'Archlinux' do
  describe 'install postfix' do
    before do
      shell('puppet module install puppet/postfix')
    end

    it do
      pp = 'include postfix'
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end
  end

  context 'default version' do
    it 'postfix_exporter works idempotently with no errors' do
      pp = 'include prometheus::postfix_exporter'
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe service('postfix_exporter') do
      it { is_expected.to be_running }
      it { is_expected.to be_enabled }
    end

    describe port(9154) do
      it { is_expected.to be_listening.with('tcp6') }
    end

    it 'provides postfix metrics' do
      shell('curl -s http://127.0.0.1:9154/metrics') do |r|
        expect(r.stdout).to match(%r{postfix_smtpd_connects_total})
      end
    end
  end
end
