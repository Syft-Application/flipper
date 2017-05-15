require 'helper'
require 'flipper/cloud'
require 'flipper/adapters/instrumented'

RSpec.describe Flipper::Cloud do
  context "initialize with token" do
    let(:token) { 'asdf' }

    before do
      @instance = described_class.new(token)
      memoized_adapter = @instance.adapter
      @http_adapter = memoized_adapter.adapter
      @http_client = @http_adapter.instance_variable_get('@client')
    end

    it 'returns Flipper::DSL instance' do
      expect(@instance).to be_instance_of(Flipper::DSL)
    end

    it 'configures instance to use http adapter' do
      expect(@http_adapter).to be_instance_of(Flipper::Adapters::Http)
    end

    it 'sets up correct url' do
      uri = @http_client.instance_variable_get('@uri')
      expect(uri.scheme).to eq('https')
      expect(uri.host).to eq('www.featureflipper.com')
      expect(uri.path).to eq('/adapter')
    end

    it 'sets correct token header' do
      headers = @http_client.instance_variable_get('@headers')
      expect(headers['Feature-Flipper-Token']).to eq(token)
    end

    it 'uses noop instrumenter' do
      expect(@instance.instrumenter).to be(Flipper::Instrumenters::Noop)
    end
  end

  context 'initialize with token and options' do
    before do
      @instance = described_class.new('asdf', url: 'https://www.fakeflipper.com/sadpanda')
      memoized_adapter = @instance.adapter
      @http_adapter = memoized_adapter.adapter
      @http_client = @http_adapter.instance_variable_get('@client')
    end

    it 'sets correct url' do
      uri = @http_client.instance_variable_get('@uri')
      expect(uri.scheme).to eq('https')
      expect(uri.host).to eq('www.fakeflipper.com')
      expect(uri.path).to eq('/sadpanda')
    end
  end

  it 'can set instrumenter' do
    instrumenter = Object.new
    instance = described_class.new('asdf', instrumenter: instrumenter)
    expect(instance.instrumenter).to be(instrumenter)
  end

  it 'allows wrapping adapter with another adapter like the instrumenter' do
    adapter_wrapper = lambda do |adapter|
      Flipper::Adapters::Instrumented.new(adapter)
    end
    instance = described_class.new('asdf', adapter_wrapper: adapter_wrapper)
    # instance.adapter is memoizable adapter instance
    expect(instance.adapter.adapter).to be_instance_of(Flipper::Adapters::Instrumented)
  end
end