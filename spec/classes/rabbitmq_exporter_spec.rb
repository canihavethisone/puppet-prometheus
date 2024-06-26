# frozen_string_literal: true

require 'spec_helper'

describe 'prometheus::rabbitmq_exporter' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(os_specific_facts(facts))
      end

      context 'with version specified' do
        let(:params) do
          {
            version: '1.0.0',
            arch: 'amd64',
            os: 'linux',
            bin_dir: '/usr/local/bin',
            install_method: 'url'
          }
        end

        describe 'compile manifest' do
          it { is_expected.to compile.with_all_deps }
        end

        describe 'install correct binary' do
          it { is_expected.to contain_file('/usr/local/bin/rabbitmq_exporter').with('target' => '/opt/rabbitmq_exporter-1.0.0.linux-amd64/rabbitmq_exporter') }
        end

        describe 'required resources' do
          it { is_expected.to contain_prometheus__daemon('rabbitmq_exporter') }
          it { is_expected.to contain_user('rabbitmq-exporter') }
          it { is_expected.to contain_group('rabbitmq-exporter') }
          it { is_expected.to contain_service('rabbitmq_exporter') }
        end

        describe 'create env_var file' do
          it 'sets publish_port env_var to scrape_port value' do
            rabbitmq_env = if facts[:os]['family'] == 'RedHat'
                             catalogue.resource('File', '/etc/sysconfig/rabbitmq_exporter').send(:parameters)[:content]
                           elsif facts[:os]['name'] == 'Archlinux'
                             catalogue.resource('File', '/etc/conf.d/rabbitmq_exporter').send(:parameters)[:content]
                           elsif facts[:os]['name'] == 'Darwin'
                             catalogue.resource('File', '/etc/rabbitmq_exporter').send(:parameters)[:content]
                           else
                             catalogue.resource('File', '/etc/default/rabbitmq_exporter').send(:parameters)[:content]
                           end
            expect(rabbitmq_env).to include('PUBLISH_PORT="9419"')
          end
        end
      end
    end
  end
end
