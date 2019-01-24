class ScreenshotJob
	
	def reschedule_at(current_time, attempts)
		current_time + 1.day
	end
	
	def perform
		blogs = Blog.all
		blogs.each do |blog|
			pages = blog.pages
			pages.each do |page|
				page.capture_screenshot(nil)
			end
		end
	rescue => e
		put e
	ensure
		raise "Job retry"
	end

end
