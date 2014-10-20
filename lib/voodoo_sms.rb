require 'httparty'

# TODO: RDoc

class VoodooSMS
  module Error
    class BadRequest < StandardError; end
    class Unauthorised < StandardError; end
    class NotEnoughCredit < StandardError; end
    class Forbidden < StandardError; end
    class MessageTooLarge < StandardError; end
    class Unexpected < StandardError; end
    class InvalidParameterFormat < StandardError; end
  end

  include HTTParty
  base_uri 'voodoosms.com'
  default_params format: 'json'
  format :json

  def initialize(username, password)
    @params = { query: { uid: username, pass: password } }
  end

  def get_credit
    make_request('getCredit')['credit']
  end

  def send_sms(originator, destination, message)
    merge_params(orig: originator, dest: destination, msg: message, validity: 1)
    make_request('sendSMS')['resultText'].to_s.include? 'OK'
  end

  def get_sms(from, to, keyword = '')
    merge_params(from: format_date(from), to: format_date(to), keyword: keyword)
    response = make_request('getSMS')['messages']
    if response.is_a?(Array)
      response.map { |r| OpenStruct.new(from: r['Originator'],
        timestamp: DateTime.parse(r['TimeStamp']),
        message: r['Message']) }
    else
      []
    end
  end

  private
    def merge_params(opts)
      @params[:query].merge!(opts)
    end

    def make_request(method)
      validate_parameters_for(method)

      begin
        response = self.class.get("/vapi/server/#{method}", @params)
      rescue => e
        raise Error::Unexpected.new(e.message)
      end

      case response['result']
      when 200, '200 OK' # inconsistencies :(
        return response
      when 'You dont have any messages'
        return {} # :(
      when 400
        raise Error::BadRequest.new(response.values.join(', '))
      when 401
        raise Error::Unauthorised.new(response.values.join(', '))
      when 402
        raise Error::NotEnoughCredit.new(response.values.join(', '))
      when 403
        raise Error::Forbidden.new(response.values.join(', '))
      when 513
        raise Error::MessageTooLarge.new(response.values.join(', '))
      else
        raise Error::Unexpected.new(response.values.join(', '))
      end
    end

    def validate_parameters_for(method)
      case method
      when 'sendSMS'
        validate_originator  @params[:query][:orig]
        validate_destination @params[:query][:dest]
      end
    end

    def validate_originator(input)
      unless input.match /^[a-zA-Z0-9]{1,11}(\d{4})?$/
        raise Error::InvalidParameterFormat.new('must be 15 numeric digits or 11 alphanumerics')
      end
    end

    def validate_destination(input)
      unless input.match /^\d{10,15}$/
        raise Error::InvalidParameterFormat.new('must be valid E.164 format')
      end
    end

    def format_date(date)
      date.respond_to?(:strftime) ? date.strftime("%F %T") : date
    end
end