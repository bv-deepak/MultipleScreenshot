require 'test_helper'

class SnapshotControllerTest < ActionDispatch::IntegrationTest
  test "should get capture" do
    get snapshot_capture_url
    assert_response :success
  end

end
