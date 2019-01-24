require "opencv"
require 'rmagick'
include Magick
include OpenCV
class Page < ApplicationRecord
	belongs_to :blog
	has_many :screenshots
	has_many :unionchanges
	has_many :diffs

	def capture_screenshot(snap_id)
		sid = DateTime.now.utc.to_i
		screenshots_home_path = "#{Rails.root}/screenshots/" + self.url.split("//")[1]
		if !File.exist?(screenshots_home_path)
			Dir.mkdir(screenshots_home_path)
			Dir.mkdir(screenshots_home_path + "/diffImages")
		end
		latest_screenshot_path = screenshots_home_path + "/#{sid}.jpg" 
		query_params = {url: self.url, proxy: "", username: "", password: ""}
		result = RestClient::Request.execute({
			url: "127.0.0.1:8080/har_and_screenshot",
			user: "",
			password: "",
			method: :post,
			payload: query_params
		})
		result = JSON.parse(result.body)
		File.open(latest_screenshot_path, "wb+") {|f| f.write Base64.decode64(result["full_site_screenshot"])}
		Screenshot.create(:blog_id => self.blog_id,
											:page_id => self.id,
											:sid => sid,
											:snapshot_id => snap_id,
											:resp_code => result["site_resp_code"])
	end

	def calculate_diff
		url = self.url
		last_two_screenshots = self.screenshots.last(2)
		@screenshots_home_path = "#{Rails.root}/screenshots/" + url.split("//")[1]
		if  last_two_screenshots.count == 2
			@latest_screenshot_path = @screenshots_home_path + "/#{last_two_screenshots.last.sid}.jpg"
			@old_screenshot_path = @screenshots_home_path + "/#{last_two_screenshots.first.sid}.jpg"
			@image1 = Image.read(@latest_screenshot_path).first
			@image2 = Image.read(@old_screenshot_path).first
			@coordinates = self.calculate_contours()
			diff_image, diff_metric = @image1.compare_channel( @image2, Magick::AbsoluteErrorMetric)
			percentage_diff = ((diff_metric*100)/(@image1.rows*@image1.columns))
			diff_image_path = "#{@screenshots_home_path}/diffImages/" + DateTime.now.to_i.to_s+".jpg"
			diff_image.write(diff_image_path)
			Diff.create(:page_id => self.id,
									:src_screenshot_id => last_two_screenshots.last.id,
									:dest_screenshot_id => last_two_screenshots.first.id,
									:coordinates => @coordinates,
									:diff_image_path => diff_image_path,
									:percentage_diff => percentage_diff)
			self.updateUnionCoordinates()
		end
	end

	def calculate_contours
		pixelsOfimg1 = @image1.dispatch(0,0,@image1.columns,@image1.rows,"I",float=true)
		pixelsOfimg2 = @image2.dispatch(0,0,@image2.columns,@image2.rows,"I",float=true)
		count = [pixelsOfimg1.count ,pixelsOfimg2.count].max
		for i in 0...count do
			pixelsOfimg2[i] = ( pixelsOfimg1[i] == pixelsOfimg2[i] ) ? 0.0 : 1.0
		end
		rows = (count == pixelsOfimg1.count)? @image1.rows : @image2.rows
		columns = (count == pixelsOfimg1.count)? @image1.columns : @image2.columns
		bitmap_diffimage = Image.constitute(columns, rows, "I", pixelsOfimg2)
		bitmap_diffimage.write("#{@screenshots_home_path}" + "/bitmap_diffimage.jpg")
		bitmap_diffimage = CvMat.load("#{@screenshots_home_path}" + "/bitmap_diffimage.jpg")
		kernel = IplConvKernel.new(14, 14, 7 , 7, :rect)
		bitmap_diffimage = bitmap_diffimage.BGR2GRAY
		bitmap_diffimage_morpholized = bitmap_diffimage.morphology(CV_MOP_CLOSE , kernel , 1)
		contour = bitmap_diffimage_morpholized.find_contours(:mode => OpenCV::CV_RETR_EXTERNAL,
																												 :method => OpenCV::CV_CHAIN_APPROX_NONE)
		contour_hash = Hash.new
		while contour
			unless contour.hole?
				box = contour.bounding_rect
				coordinates = [box.top_left.x, box.top_left.y, box.bottom_right.x, box.bottom_right.y]
				contour_hash[coordinates] = [99999999999, 1, DateTime.now.utc]
				contour = contour.h_next
			end
		end
		return contour_hash
	end

	def updateUnionCoordinates
		@union_changes = self.unionchanges
		@coordinates.each do |coordinate,value|
			x1 = coordinate.first
			y1 = coordinate.second
			x2 = coordinate.third
			y2 = coordinate.fourth
			if @union_changes.empty?
				union_coordinate = [x1, y1, x2, y2]
				union_value = [99999999999, 1, DateTime.now.utc]
				union_hash = {union_coordinate => union_value}
				Unionchange.create(:page_id => self.id, :coordinates => union_hash)
			else
				flag = false
				@union_changes.each do |union_change|
					union_hash = union_change.coordinates
					union_coordinate =	union_hash.keys.first
					union_value = union_hash.values.first
					ux1 = union_coordinate.first
					uy1 = union_coordinate.second
					ux2 = union_coordinate.third
					uy2 = union_coordinate.fourth
					if (((ux1 <= x1 && x1 <= ux2 || ux1 <= x2 && x2 <= ux2) ||
							 ((x1 <= ux1 && ux1 <= x2) && (x1 <= ux2 && ux2 <= x2))) &&
							((uy1 <= y1 && y1 <= uy2 || uy1 <= y2 && y2 <= uy2) ||
							 ((y1 <= uy1 && uy1 <= y2) && (y1 <= uy2 && uy2 <= y2))))
						flag = true
						if ux1 > x1
							ux1 = x1
						end
						if ux2 < x2
							ux2 = x2
						end
						if uy1 > y1
							uy1 = y1
						end
						if uy2 < y2
							uy2 = y2
						end
						updated_union_coordinate = [ux1, uy1, ux2, uy2]
						union_value[0] = [union_value.first, (DateTime.now.utc - union_value.third)].min
						union_value[1] += 1
						union_value[2] = DateTime.now.utc
						updated_union_hash = {updated_union_coordinate => union_value}
						union_change.coordinates = updated_union_hash
						union_change.save
					end
				end
				if !flag
					new_union_coordinate = [x1, y1, x2, y2]
					new_union_value = [99999999999, 1, DateTime.now.utc]
					new_union_hash = {new_union_coordinate => new_union_value}
					Unionchange.create(:page_id => self.id, :coordinates => new_union_hash)
				end
			end
		end
	end

	def getAllDiff
		hash = Hash.new
		all_diffs = self.diffs
		all_diffs.each do |diff|
			appeared_at = diff.created_at
			coordinates = diff.coordinates
			coordinates.each do |coordinate,values|
				if (!hash.include?(coordinate))
					hash[coordinate] = [999999999999999, 1, appeared_at]
				else
					old_values=hash[coordinate]
					values[0] = [ old_values[0], appeared_at-old_values[2]].min
					values[1] += 1
					values[2] = appeared_at
					hash[coordinate] = values
				end
			end
		end
		return hash
	end

end
