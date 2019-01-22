require 'restclient'
require 'json'
class CaptureScreenshot
   def take_screenshot(page_url)
       query_params = { url: page_url, proxy: "", username: "", password: "" }
       result = RestClient::Request.execute({ url: "127.0.0.1:8080/har_and_screenshot", user: "", password: "", method: :post, payload: query_params })
       result = JSON.parse(result.body)
   end    
end	