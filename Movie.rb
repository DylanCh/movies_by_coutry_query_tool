class Movie
	def initialize(_title, _description, _original_title, _directors)
		@title = _title
		@description = _description
		@original_title = _original_title
		@directors = _directors
	end

	def title
		@title
	end

	def description
		@description
	end

	def original_title
		@original_title
	end

	def directors #List<Director>
		@directors
	end
end