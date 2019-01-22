require 'test_helper'

class BlogControllerTest < ActionDispatch::IntegrationTest
  test "should get capture" do
    get blog_capture_url
    assert_response :success
  end

end
