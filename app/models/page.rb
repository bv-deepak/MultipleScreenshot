class Page < ApplicationRecord
	belongs_to :blog
    has_many :screenshots
    has_many :unionchanges
    has_many :diffs
	def capture_screenshot( snap_id )
		query_params = { url: self.url, proxy: "", username: "", password: "" }
		result = RestClient::Request.execute({ url: "127.0.0.1:8080/har_and_screenshot", user: "", password: "", method: :post, payload: query_params })
		result = JSON.parse(result.body)
		sid = DateTime.now.utc.to_i
		File.open(Rails.root.to_s+"/screenshots/#{sid}"+".jpg", "wb+") {|f| f.write Base64.decode64(result["full_site_screenshot"])}
	    Screenshot.create( :page_id => self.id, :blog_id => self.blog_id, :sid => sid.to_s, :snapshot_id => snap_id ) 		
	end
	#def take_screenshot( page_url )
	#	query_params = { url: page_url, proxy: "", username: "", password: "" }
	#	result = RestClient::Request.execute({ url: "127.0.0.1:8080/har_and_screenshot", user: "", password: "", method: :post, payload: query_params })
	#	result = JSON.parse(result.body)
	#end
end
		