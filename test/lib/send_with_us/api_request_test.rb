require_relative '../../test_helper'

class TestApiRequest < MiniTest::Unit::TestCase

  def build_objects
    @payload = {}
    @api = SendWithUs::Api.new( api_key: 'THIS_IS_A_TEST_API_KEY', debug: false)
    @config  = SendWithUs::Config.new( api_version: '1_0', api_key: 'THIS_IS_A_TEST_API_KEY', debug: false )
    @request = SendWithUs::ApiRequest.new(@config)
  end

  def test_payload
    build_objects
    Net::HTTP.any_instance.stubs(:request).returns(Net::HTTPSuccess.new(1.0, 200, "OK"))
    assert_instance_of( Net::HTTPSuccess, @request.post(:send, @payload) )
  end

  def test_attachment
    build_objects
    email_id = 'test_fixture_1'
    result = @api.send_with(
        email_id,
        {name: 'Ruby Unit Test', address: 'matt@example.com'},
        {name: 'sendwithus', address: 'matt@example.com'},
        {},
        [],
        [],
        ['README.md']
    )
    assert_instance_of( Net::HTTPOK, result )
  end

  def test_unsubscribe
    build_objects
    Net::HTTP.any_instance.stubs(:request).returns(Net::HTTPSuccess.new(1.0, 200, "OK"))
    assert_instance_of( Net::HTTPSuccess, @request.post(:'drips/unsubscribe', @payload) )
  end

  def test_send_with_not_found_exception
    build_objects
    Net::HTTP.any_instance.stubs(:request).returns(Net::HTTPNotFound.new(1.0, 404, "OK"))
    assert_raises( SendWithUs::ApiInvalidEndpoint ) { @request.post(:send, @payload) }
  end

  def test_send_with_forbidden_exception
    build_objects
    Net::HTTP.any_instance.stubs(:request).returns(Net::HTTPForbidden.new(1.0, 403, "OK"))
    assert_raises( SendWithUs::ApiInvalidKey ) { @request.post(:send, @payload) }
  end

  def test_send_with_bad_request
    build_objects
    Net::HTTP.any_instance.stubs(:request).returns(Net::HTTPBadRequest.new(1.0, 400, "OK"))
    assert_raises( SendWithUs::ApiBadRequest ) { @request.post(:send, @payload) }
  end

  def test_send_with_unknown_exception
    build_objects
    Net::HTTP.any_instance.stubs(:request).returns(Net::HTTPNotAcceptable.new(1.0, 406, "OK"))
    assert_raises( SendWithUs::ApiUnknownError ) { @request.post(:send, @payload) }
  end

  def test_send_with_connection_refused
    build_objects
    Net::HTTP.any_instance.stubs(:request).raises(Errno::ECONNREFUSED.new)
    assert_raises( SendWithUs::ApiConnectionRefused ) { @request.post(:send, @payload) }
  end

  def test_emails
    build_objects
    Net::HTTP.any_instance.stubs(:request).returns(Net::HTTPSuccess.new(1.0, 200, "OK"))
    assert_instance_of( Net::HTTPSuccess, @request.get(:emails) )
  end

  def test_request_path
    build_objects
    assert_equal( true, @request.send(:request_path, :send) == '/api/v1_0/send' )
  end
end
