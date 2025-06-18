local CollectionService = game:GetService("CollectionService")


export type chapter = {
	identifier: string?,
	priority: number?,
	init: (self: chapter) -> ()?,
	start: (self: chapter) -> ()?,
	destroy: (self: chapter) -> ()?,
	-- This could change into a reference to the bookmark, which could be safer, but this is easier for the user.
	-- And getting reference to interal bookmark kinda no make sense idk
	bookmarks: { string },
	[string]: any,
}
export type bookmark = chapter & {
	chapters: { chapter }?,
	run_chapter_method: (self: bookmark,async: boolean) -> (),
	chapter_added: ((self: bookmark, chapter: chapter) -> ())?,
	chapter_removed: ((self: bookmark, chapter: chapter) -> ())?,
}

export type character = chapter & {
	tag: string?,
	instance: Instance?,
	[string]: any,
}

export type quill = {
	_chapters: { [string]: chapter },
	_bookmarks: { [string]: bookmark },
	_characters: { [string]: { [Instance]: character } },
	_character_definitions: { [string]: character },

	register_chapter: (self: quill, mod: ModuleScript) -> quill,
	register_chapters: (self: quill, container: Folder) -> quill,
	register_character: (self: quill, definition: character) -> quill,
	register_characters: (self: quill, container: Folder) -> quill,
	register_bookmark: (self: quill, mod: ModuleScript) -> quill,
	register_bookmarks: (self: quill, container: Folder) -> quill,
	register_default_bookmarks: (self: quill) -> quill,
	begin_reading: (self: quill) -> (),
}

local function constructor(): quill
	local self = {} :: quill

	self._chapters = {}
	self._bookmarks = {}
	self._characters = {}
	self._character_definitions = {}

	local function run_chapter_method(chapters: { chapter }, lifecycle_name: string, async: boolean?)
		for _, chapter in chapters do
			local fn = chapter[lifecycle_name]
			if fn then
				if async == true then
					task.spawn(fn, chapter)
				else
					fn(chapter)
				end
			end
		end
	end

	local function bookmark_run_chapter_method(self: bookmark, async: boolean?)
		run_chapter_method(self.chapters, self.identifier :: string,async)
	end

	function self:register_bookmark(mod: ModuleScript): quill
		if self._bookmarks[mod.Name] then
			return self
		end

		local bookmark: bookmark = require(mod) :: any
		bookmark.identifier = mod.Name
		bookmark.priority = bookmark.priority or 1
		bookmark.chapters = {}
		bookmark.run_chapter_method = bookmark_run_chapter_method

		assert(not bookmark.init or typeof(bookmark.init) == "function", `Bookmark {mod.Name} init must be a function`)
		assert(not bookmark.start or typeof(bookmark.start) == "function", `Bookmark {mod.Name} start must be a function`)
		assert(not bookmark.destroy or typeof(bookmark.destroy) == "function", `Bookmark {mod.Name} destroy must be a function`)
		assert(not bookmark.chapter_added or typeof(bookmark.chapter_added) == "function", `Bookmark {mod.Name} chapter_added must be a function`)
		assert(not bookmark.chapter_removed or typeof(bookmark.chapter_removed) == "function", `Bookmark {mod.Name} chapter_removed must be a function`)

		self._bookmarks[mod.Name] = bookmark

		return self
	end

	function self:register_bookmarks(container: Folder): quill
		for _, child in container:GetChildren() do
			if child:IsA("ModuleScript") then
				self:register_bookmark(child)
			end
		end
		return self
	end

	function self:register_default_bookmarks(): quill
		return self:register_bookmarks(script.bookmarks)
	end

	local function place_bookmark(chapter: chapter, bookmark: bookmark)
		table.insert(bookmark.chapters, chapter)
		table.sort(bookmark.chapters, function(a, b)
			return a.priority > b.priority
		end)
		if bookmark.chapter_added then
			bookmark:chapter_added(chapter)
		end
	end

	local function place_bookmarks(chapter: chapter, bookmarks: { bookmark })
		for _, bookmark in bookmarks do
			place_bookmark(chapter, bookmark)
		end
	end

	local function get_bookmarks(bookmarks: { string }): { bookmark }
		local bookmarkTable = {}

		for _, name in bookmarks do
			table.insert(bookmarkTable,self._bookmarks[name])
		end
		return bookmarkTable
	end

	function self:register_chapter(mod: ModuleScript): quill
		if self._chapters[mod.Name] then
			return self
		end

		local chapter: chapter = require(mod) :: any
		chapter.identifier = mod.Name
		chapter.priority = chapter.priority or 1

		assert(not chapter.init or typeof(chapter.init) == "function", `Chapter {mod.Name} init must be a function`)
		assert(not chapter.start or typeof(chapter.start) == "function", `Chapter {mod.Name} start must be a function`)
		assert(
			not chapter.destroy or typeof(chapter.destroy) == "function",
			`Chapter {mod.Name} destroy must be a function`
		)
		assert(typeof(chapter.priority) == "number", `Chapter {mod.Name} priority must be a number`)

		self._chapters[mod.Name] = chapter

		if chapter.bookmarks ~= nil then
			place_bookmarks(chapter, get_bookmarks(chapter.bookmarks))
		end
		

		return self
	end

	function self:register_chapters(container: Folder): quill
		for _, child in container:GetChildren() do
			if child:IsA("ModuleScript") then
				self:register_chapter(child)
			end
		end
		return self
	end



	function self:register_character(definition: character): quill
		assert(type(definition.tag) == "string", "Character must have a tag string")
		if self._character_definitions[definition.tag] then
			warn(`Character tag '{definition.tag}' already registered; skipping`)
			return self
		end

		self._character_definitions[definition.tag] = definition
		self._characters[definition.tag] = {}

		local function on_instance_added(instance: Instance)
			local clone = {} :: character
			clone.instance = instance

			for k, v in pairs(definition) do
				clone[k] = v
			end

			self._characters[definition.tag][instance] = clone

			if definition.bookmarks ~= nil then
				place_bookmarks(definition, get_bookmarks(definition.bookmarks))
			end

			if clone.init then
				clone:init(instance)
			end

			if clone.start then
				task.spawn(clone.start, clone)
			end
		end

		local function on_instance_removed(instance: Instance)
			local char = self._characters[definition.tag][instance]
			if char and char.destroy then
				local ok, err = pcall(char.destroy, char)
				if not ok then
					warn(`[quill] Error destroying character {definition.tag}: {err}`)
				end
			end
			self._characters[definition.tag][instance] = nil
		end

		CollectionService:GetInstanceAddedSignal(definition.tag):Connect(on_instance_added)
		CollectionService:GetInstanceRemovedSignal(definition.tag):Connect(on_instance_removed)

		for _, instance in CollectionService:GetTagged(definition.tag) do
			on_instance_added(instance)
		end

		return self
	end

	function self:register_characters(container: Folder): quill
		for _, child in container:GetChildren() do
			if child:IsA("ModuleScript") then
				local success, char: character = pcall(require, child)
				if success and char and char.tag then
					self:register_character(char)
				else
					warn(`[quill] Failed to load character module '{child.Name}'`)
				end
			end
		end
		return self
	end

	function self:begin_reading()

		local bookmark_list = table.clone(self._bookmarks)
		for _, bookmark in self._bookmarks do
			table.insert(bookmark_list, bookmark)
		end


		table.sort(bookmark_list, function(a, b)
			return a.priority > b.priority
		end)

		run_chapter_method(bookmark_list, "init")
		run_chapter_method(bookmark_list, "start", true)

		local chapter_list = table.clone(self._chapters)
		for _, chapter in self._chapters do
			table.insert(chapter_list, chapter)
		end
		
		table.sort(chapter_list, function(a, b)
			return a.priority > b.priority
		end)
		run_chapter_method(chapter_list, "init")
		run_chapter_method(chapter_list, "start", true)

		print(`[quill] Loaded {#chapter_list} chapters.`)
	end

	return self
end

return constructor
