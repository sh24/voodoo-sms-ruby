require 'spec_helper'

describe VoodooSMS do
  let(:client) { VoodooSMS.new('username', 'password') }

  describe :send_sms do
    let(:orig) { 'SENDERID' }
    let(:dest) { '447123456789' }
    let(:msg) { 'Test message' }

    context '200 success', vcr: :success do
      let(:vcr_cassette) { 'send_sms' }
      it { expect(client.send_sms(orig, dest, msg)).to eq('4103395') }
    end

    context '200 success - multipart message', vcr: :success do
      let(:vcr_cassette) { 'send_multipart_sms' }
      it { expect(client.send_sms(orig, dest, 'A' * 320)).to eq('4103395') }
    end

    context 'Voodoo has changed response json, reference_id is renamed to message_id', vcr: :success do
      let(:vcr_cassette) { 'send_sms_response_changed' }
      it { expect { client.send_sms(orig, dest, msg) }.to raise_error VoodooSMS::Error::Unexpected }
    end

    context 'validation' do
      before(:each) do
        response = double('HTTParty::Response',
                          parsed_response: { 'result' => 200, 'resultText' => '200 OK', 'reference_id' => '4103395' })
        allow(response).to receive(:[]).with('result').and_return('200 OK')
        allow(VoodooSMS).to receive(:get).and_return(response)
      end

      context 'originator parameter' do
        it 'allows a maximum of 15 numeric digits' do
          expect { client.send_sms('0' * 15, dest, msg) }.to_not raise_error
        end

        it 'allows a maximum of 11 alphanumerics' do
          expect { client.send_sms("#{'0A' * 5}0", dest, msg) }.to_not raise_error
        end

        it 'does not allow nil entries' do
          expect { client.send_sms(nil, dest, msg) }.to raise_error VoodooSMS::Error::RequiredParameter
        end

        it 'does not allow blank entry' do
          expect { client.send_sms('', dest, msg) }.to raise_error VoodooSMS::Error::RequiredParameter
        end

        it 'does not allow input longer than 15 numerics digits' do
          expect { client.send_sms('0' * 16, dest, msg) }.to raise_error VoodooSMS::Error::InvalidParameterFormat
        end

        it 'does not allow input longer than 11 alphanumerics' do
          expect { client.send_sms('0A' * 6, dest, msg) }.to raise_error VoodooSMS::Error::InvalidParameterFormat
        end
      end

      context 'destination parameter' do
        it 'allows a maximum of 10 numeric digits' do
          expect { client.send_sms(orig, '0' * 10, msg) }.to_not raise_error
        end

        it 'allows a maximum of 15 numeric digits' do
          expect { client.send_sms(orig, '0' * 15, msg) }.to_not raise_error
        end

        it 'does not allow nil entries' do
          expect { client.send_sms(orig, nil, msg) }.to raise_error VoodooSMS::Error::RequiredParameter
        end

        it 'does not allow blank entry' do
          expect { client.send_sms(orig, '', msg) }.to raise_error VoodooSMS::Error::RequiredParameter
        end

        it 'does not allow invalid E.164 formats' do
          expect { client.send_sms(orig, 'ABC', msg) }.to raise_error VoodooSMS::Error::InvalidParameterFormat
        end
      end
    end
  end
end
