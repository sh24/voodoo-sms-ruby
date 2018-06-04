require 'httparty'
require 'voodoo_sms/errors'

# TODO: Refactor this into action classes (ie. VoodooSMS::GetCredit.call)

class VoodooSMS

  include HTTParty
  base_uri 'https://voodoosms.com'
  default_params format: 'json'
  format :json

  def initialize(username, password)
    @params = { query: { uid: username, pass: password } }
  end

  def get_credit
    response = make_request('getCredit')
    fetch_from_response(response, 'credit')
  end

  def send_sms(originator, destination, message)
    merge_params(orig: originator, dest: destination, msg: message, validity: 1)
    response = make_request('sendSMS').parsed_response
    fetch_from_response(response, 'reference_id')
  end

  def get_sms(from, to, keyword = '')
    merge_params(from: format_date(from), to: format_date(to), keyword: keyword)
    response = Array(make_request('getSMS')['messages']) # unfortunately we can't use fetch_from_response as the 'messages' key is not present when there are no messages.
    response.map do |message|
      OpenStruct.new(from: message['Originator'],
                     timestamp: DateTime.parse(message['TimeStamp']),
                     message: message['Message'])
    end
  end

  def get_delivery_status(reference_id)
    merge_params(reference_id: reference_id)
    response = make_request('getDlrStatus')
    fetch_from_response(response, 'delivery_status')
  end

  private

  def merge_params(opts)
    @params[:query].merge!(opts)
  end

  def make_request(method)
    validate_parameters_for(method)

    response = send_request!(method)

    case response['result']
    when 200, '200 OK' # inconsistencies :(
      return response
    when 'You dont have any messages'
      return {} # :(
    when 400 then raise Error::BadRequest,      response.values.join(', ')
    when 401 then raise Error::Unauthorised,    response.values.join(', ')
    when 402 then raise Error::NotEnoughCredit, response.values.join(', ')
    when 403 then raise Error::Forbidden,       response.values.join(', ')
    when 513 then raise Error::MessageTooLarge, response.values.join(', ')
    else
      raise Error::Unexpected, response.values.join(', ')
    end
  end

  def send_request!(method)
    self.class.get("/vapi/server/#{method}", @params)
  rescue StandardError => e
    raise Error::Unexpected, e.message
  end

  def validate_parameters_for(method)
    case method
    when 'sendSMS'
      validate_originator  @params[:query][:orig]
      validate_destination @params[:query][:dest]
    end
  end

  def validate_originator(input)
    raise Error::RequiredParameter if input.nil? || input.empty?
    raise Error::InvalidParameterFormat, 'must be 15 numeric digits or 11 alphanumerics' unless input =~ /^[a-zA-Z0-9]{1,11}(\d{4})?$/
  end

  def validate_destination(input)
    raise Error::RequiredParameter if input.nil? || input.empty?
    raise Error::InvalidParameterFormat, 'must be valid E.164 format' unless input =~ /^\d{10,15}$/
  end

  def format_date(date)
    date.respond_to?(:strftime) ? date.strftime('%F %T') : date
  end

  def fetch_from_response(response, key)
    response.fetch(key) { raise Error::Unexpected, "No #{key} found from Voodoo response!" }
  end
end
