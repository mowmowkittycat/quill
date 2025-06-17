<h1 align="center">
	<a href="https://featherfall.gitbook.io/quill">
		<img src="images/logo.png" alt="Reflex" width="200" />
	</a>
	<br />
	<b>Quill</b>
</h1>

<div align="center">

The <b>best</b> all-in-one lightweight Roblox game framework.
 
</div>

---

&nbsp;

## 🪶 Quill

**Quill** is a book-inspired Roblox game framework inspired by [Sapphire](https://github.com/Mark-Marks/sapphire), designed to simplify your workflow's setup.

You can use Quill for Chapters (services/controllers) and Characters (components). Eventually, you will be able to use Quill to handle networking, data saving, and will be able to add your own extensions.

&nbsp;

## 📦 Installation

This package is available for [Wally](https://wally.run/package/featherfall-org/quill) and Pesde.

```toml
# wally.toml
[dependencies]
quill = "featherfall-org/quill@0.1.0-alpha"

#pesde.toml
[dependencies]
quill = { wally = "featherfall-org/quill", version = "0.1.0-alpha" }
```

&nbsp;

## 📚 Getting Started

[Take me to the documentation →](https://featherfall.gitbook.io/quill)

### 🚀 Start using Quill

Quill requires some sort of bootstrapper to launch your lifecycle hooks. You can start by making bootstrappers for the server and client.

```lua
local quill = require(path.to.quill)

quill()
    :register_chapters(script.chapters)
    :register_characters(script.characters)
    :begin_reading()
```

### 📖 Using Chapters

Now that you have made your bootstrappers, you can begin writing your Chapters. Here's what a Chapter might look like:

```lua
local Players = game:GetService("Players")

local example = {
    priority = 1,
}

function example:player_added(player: Player)
    print(player.Name .. " has joined the game!")
end

function example:state_something(statement: string)
    print(statement)
end

function example:init()
    Players.PlayerAdded:Connect(function(player)
        self:player_added(player)
    end)
end

return example
```

### 👤 Using Characters

You may also want to include components in your workflow; Quill provides components that are called Characters. Here's what a Character might look like:

```lua
local example = {
    tag = "Example_Tag",
}

function example:init()
    print("Character is attached to " .. self.instance:GetFullName())
end

function example:destroy()
    print("Character " .. self.instance:GetFullName() .. " has been destroyed!")
end

return example
```

&nbsp;

## 📺 Credits

Credits go to [Mark-Marks](https://github.com/Mark-Marks) for the creation of Sapphire and its architecture, which is what Quill draws its inspiration from, and [littensy](https://github.com/littensy) for the documentation and README inspiration.

&nbsp;

## 📝 License

Quill is licensed under the [MIT License](LICENSE.md).