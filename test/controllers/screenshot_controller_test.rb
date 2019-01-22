require 'test_helper'

class ScreenshotControllerTest < ActionDispatch::IntegrationTest
  test "should get capture" do
    get screenshot_capture_url
    assert_response :success
  end

end
