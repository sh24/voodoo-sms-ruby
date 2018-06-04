require 'spec_helper'

describe VoodooSMS do
  let(:client) { VoodooSMS.new('username', 'password') }

  describe :get_delivery_status do
    context '200 success', vcr: :success do
      let(:vcr_cassette) { 'get_delivery_status' }
      it { expect(client.get_delivery_status('5143598')).to eq 'Delivered' }
    end

    context 'Voodoo has changed response json, reference_id is renamed to message_id', vcr: :success do
      let(:vcr_cassette) { 'get_delivery_status_response_changed' }
      it { expect { client.get_delivery_status('5143598') }.to raise_error VoodooSMS::Error::Unexpected }
    end

    context 'Message is not delivered, Voodoo responds with empty status', vcr: :success do
      let(:vcr_cassette) { 'get_delivery_status_response_empty' }
      it { expect(client.get_delivery_status('5159497')).to be_nil }
    end
  end
end
