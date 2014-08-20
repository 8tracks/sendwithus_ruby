require "base64"

module SendWithUs
  class ApiNilEmailId < StandardError; end

  class Api
    attr_reader :configuration

    # ------------------------------ Class Methods ------------------------------

    def self.configuration
      @configuration ||= SendWithUs::Config.new
    end

    def self.configure
      yield self.configuration if block_given?
    end

    # ------------------------------ Instance Methods ------------------------------

    def initialize(options = {})
      settings = SendWithUs::Api.configuration.settings.merge(options)
      @configuration = SendWithUs::Config.new(settings)
    end

    def build_send_payload(email_id, to, data ={}, params = {})
      if email_id.nil?
        raise SendWithUs::ApiNilEmailId, 'email_id cannot be nil'
      end

      payload = {
        email_id: email_id,
        recipient: to,
        email_data: data
      }

      if files = params.delete(:files)
        files.each do |path|
          file = open(path).read
          id = File.basename(path)
          data = Base64.encode64(file)
          if payload[:files].nil?
            payload[:files] = []
          end
          payload[:files] << {id: id, data: data}
        end
      end

      if params.any?
        payload.merge!(params)
      end
      payload
    end


    # Sends multiple emails through one post request
    # send_params : array of send's params
    def batched_send(send_params_array)
      debugger
      batched_payload = []

      send_params_array.each do |sp|
        batched_payload << {
          path: '/api/v1/send',
          method: 'POST',
          body: build_send_payload(*sp)
        }
      end

      batched_payload_json = batched_payload.to_json
      SendWithUs::ApiRequest.new(@configuration).post(:batch, batched_payload_json)
    end

    # custom 8tracks method
    def send(email_id, to, data = {}, params={})
      payload_json = build_send_payload(email_id, to, data, params).to_json
      SendWithUs::ApiRequest.new(@configuration).post(:send, payload_json)
    end


    def send_with(email_id, to, data = {}, from = {}, cc={}, bcc={}, files=[])
      if email_id.nil?
        raise SendWithUs::ApiNilEmailId, 'email_id cannot be nil'
      end

      payload = { email_id: email_id, recipient: to,
        email_data: data }

      if from.any?
        payload[:sender] = from
      end
      if cc.any?
        payload[:cc] = cc
      end
      if bcc.any?
        payload[:bcc] = bcc
      end

      files.each do |path|
        file = open(path).read
        id = File.basename(path)
        data = Base64.encode64(file)
        if payload[:files].nil?
          payload[:files] = []
        end
        payload[:files] << {id: id, data: data}
      end

      payload = payload.to_json
      SendWithUs::ApiRequest.new(@configuration).post(:send, payload)
    end

    def drips_unsubscribe(email_address)

      if email_address.nil?
        raise SendWithUs::ApiNilEmailId, 'email_address cannot be nil'
      end

      payload = { email_address: email_address }
      payload = payload.to_json

      SendWithUs::ApiRequest.new(@configuration).post(:'drips/unsubscribe', payload)
    end

    def emails()
      SendWithUs::ApiRequest.new(@configuration).get(:emails)
    end

    def create_template(name, subject, html, text)
      payload = {
        name: name,
        subject: subject,
        html: html,
        text: text
      }.to_json

      SendWithUs::ApiRequest.new(@configuration).post(:emails, payload)
    end

  end

end
