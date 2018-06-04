require 'spec_helper'

describe VoodooSMS do
  let(:client) { VoodooSMS.new('username', 'password') }

  describe :get_sms do
    context '200 success', vcr: :success do
      describe 'without a keyword' do
        let(:vcr_cassette) { 'get_sms' }
        it 'returns an array of messages' do
          response = client.get_sms(DateTime.new(2014, 10, 10, 12, 0, 0),
                                    DateTime.new(2014, 10, 17, 12, 0, 0))
          expect(response.count).to eq 2
          expect(response.first.message).to eq 'SMS Body'
          expect(response.first.timestamp).to be_a DateTime
          expect(response.first.from).to eq '447000000002'
        end
      end

      describe 'with a keyword' do
        let(:vcr_cassette) { 'get_sms_with_keyword' }
        it 'returns an array of messages' do
          response = client.get_sms(DateTime.new(2014, 10, 10),
                                    DateTime.new(2014, 10, 17),
                                    'TEMP')
          expect(response.count).to eq 2
          expect(response.first.message).to eq 'TEMP'
          expect(response.first.timestamp).to be_a DateTime
          expect(response.first.from).to eq '447000000002'
        end
      end

      describe 'no messages returned' do
        let(:vcr_cassette) { 'get_sms_empty' }
        it 'returns an array of messages' do
          expect(client.get_sms(DateTime.new(2014, 10, 17, 12, 0, 0),
                                DateTime.new(2014, 10, 10, 12, 0, 0))).to eq []
        end
      end
    end
  end
end
