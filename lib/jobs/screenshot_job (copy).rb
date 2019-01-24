require "opencv"
require 'rmagick' 
require 'restclient'
require 'date'
include Magick
include OpenCV

class ScreenshotJob 
	def reschedule_at(current_time, attempts)
		current_time+1.day
	end

	def perform_task(page)
		@page = page
		url = @page.url
		screenshots = @page.screenshots
		@screenshots_home_path= "#{Rails.root}/Screenshot/" + url.split("//")[1]
		if  screenshots.last != nil
			@screenshot_first_path = @screenshots_home_path+"/#{screenshots.last.sid}.jpg"
		else
			@screenshot_first_path = nil
		end
		@sid = DateTime.now.utc.to_i
		@screenshot_second_path = @screenshots_home_path+"/#{@sid}.jpg"
		if !File.exist?(@screenshots_home_path)
			Dir.mkdir(@screenshots_home_path)
		end   
		respCode = take_screenshot(url)
		@screenshot= Screenshot.new( :blog_id => page.blog_id, :page_id => @page.id , :sid => @sid, :snapshot_id => snap_id , :resp_code => respCode )
		@screenshot.save
		if @screenshot_first_path != nil  
			@image1 = Image.read( @screenshot_first_path ).first
			@image2 = Image.read( @screenshot_second_path ).first
			@coordinates = calculate_contours()
			diff_image, diff_metric  = @image1.compare_channel( @image2, Magick::MeanSquaredErrorMetric)
			if !File.exist?(@screenshots_home_path+"/diffImages")
				Dir.mkdir(@screenshots_home_path+"/diffImages")
			end          
			diff_image_path="#{@screenshots_home_path}/diffImages/"+DateTime.now.to_i.to_s+".jpg"
			diff_image.write(diff_image_path)
			Diff.create(:page_id => @page.id, :src_screenshot_id => @screenshot.id, :dest_screenshot_id => screenshots.last.id, :coordinates => @coordinates, :diff_image_path => diff_image_path )
			@union_changes = @page.unionchanges
			updateUnionCoordinates()
		end
	end

	def perform 
		blogs = Blog.all
		blogs.each do |blog|
			pages = blog.pages
			pages.each do |page|
				perform_task(page)
			end
		end
	rescue => e
		put e
	ensure
		raise "Job retry"
	end


	def calculate_contours
		pixelsOfimg1 = @image1.dispatch( 0,0,@image1.columns,@image1.rows,"I",float=true )
		pixelsOfimg2 = @image2.dispatch( 0,0,@image2.columns,@image2.rows,"I",float=true )
		count = [pixelsOfimg1.count ,pixelsOfimg2.count].max
		for i in 0...count do 
			pixelsOfimg2[i] = ( pixelsOfimg1[i] == pixelsOfimg2[i] ) ? 0.0 : 1.0
		end
		rows = (count == pixelsOfimg1.count)? @image1.rows : @image2.rows
		columns = (count == pixelsOfimg1.count)? @image1.columns : @image2.columns
		bitmap_diffimage = Image.constitute(columns, rows, "I", pixelsOfimg2)
		bitmap_diffimage.write( "#{@screenshots_home_path}"+"/bitmap_diffimage.jpg" )
		bitmap_diffimage = CvMat.load( "#{@screenshots_home_path}"+"/bitmap_diffimage.jpg")
		kernel = IplConvKernel.new( 14, 14, 7 , 7, :rect )
		bitmap_diffimage = bitmap_diffimage.BGR2GRAY
		bitmap_diffimage_morpholized = bitmap_diffimage.morphology( CV_MOP_CLOSE , kernel , 1 )
		contour = bitmap_diffimage_morpholized.find_contours( :mode => OpenCV::CV_RETR_EXTERNAL, :method => OpenCV::CV_CHAIN_APPROX_NONE )
		contour_hash=Hash.new
		while contour
			unless contour.hole?
				box = contour.bounding_rect
				coordinates =[box.top_left.x, box.top_left.y, box.bottom_right.x, box.bottom_right.y]
				contour_hash[coordinates] = [99999999999, 1, DateTime.now.utc]
				contour = contour.h_next
			end 
		end
		return contour_hash
	end

	def updateUnionCoordinates	
		@coordinates.each do |coordinate,value|
			x1= coordinate.first
			y1= coordinate.second
			x2= coordinate.third
			y2= coordinate.fourth
			if @union_changes.empty?
				union_coordinate = [x1,y1,x2,y2]
				union_value = [99999999999, 1, DateTime.now.utc]
				union_hash = { union_coordinate => union_value }
				Unionchange.create(:page_id => @page.id, :coordinates => union_hash )
			else 
				flag = false
				@union_changes.each do |union_change|
					debugger
					union_hash = union_change.coordinates
					union_coordinate =	union_hash.keys.first
					union_value = union_hash.values.first
					ux1= union_coordinate.first
					uy1= union_coordinate.second
					ux2= union_coordinate.third
					uy2= union_coordinate.fourth
					if ((( ux1<=x1&&x1<=ux2 || ux1<=x2&&x2<=ux2) || ((x1<=ux1&&ux1<=x2)&&(x1<=ux2&&ux2<=x2))) && ((uy1<=y1&&y1<=uy2 || uy1<=y2&&y2<=uy2) || ((y1<=uy1&&uy1<=y2)&&(y1<=uy2&&uy2<=y2))))
						flag = true
						if ux1 > x1
							ux1=x1
						end
						if ux2 < x2
							ux2=x2
						end  
						if uy1 >y1
							uy1=y1
						end
						if uy2 <y2
							uy2=y2
						end
						updated_union_coordinate=[ux1,uy1,ux2,uy2]
						union_value[0] = [ union_value.first, (DateTime.now.utc - union_value.third) ].min
						union_value[1]+= 1
						union_value[2] = DateTime.now.utc
						updated_union_hash = { updated_union_coordinate => union_value }
						union_change.coordinates = updated_union_hash
						union_change.save
					end
				end
				if !flag
					new_union_coordinate=[x1,y1,x2,y2]
					new_union_value = [ 99999999999, 1, DateTime.now.utc ]
					new_union_hash = { new_union_coordinate => new_union_value }
					Unionchange.create(:page_id => @page.id, :coordinates => new_union_hash) 
				end
			end
		end
	end
	def take_screenshot( page_url )
		query_params = { url: page_url, proxy: "", username: "", password: "" }
		result = RestClient::Request.execute({ url: "127.0.0.1:8080/har_and_screenshot", user: "", password: "", method: :post, payload: query_params })
		result = JSON.parse(result.body)
		File.open(@screenshot_second_path, "wb+") {|f| f.write Base64.decode64(result["full_site_screenshot"])}
		return result["site_resp_code"]
	end
end  
