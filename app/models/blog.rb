class Blog < ApplicationRecord
	has_many :snapshots
	has_many :pages
	has_many :screenshots
end
