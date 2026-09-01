# Contributing to Project Rainbow

There are many way to help Project Rainbow development, anything from code contribution to UI design help and QoL improvement are all welcomes. You should probably join the [IMF discord](https://discord.gg/wQWa62n5xJ) and ask about on where to start and what to actually contribute. If you want to get started with contributing to the code of the engine keep reading for everything else discuss in the discord.

## How to Contribute Code

### Prerequisite

Before actually starting here are all the setup and prerequisite you need. If you have `nix` go [here](#if-you-have-nix), else go [here](#if-you-do-not-have-nix). In either case you need to make a fork of the project using the github fork feature.

#### If you have nix

If you have `nix` with `flakes` enabled and git, you can contribute by running the following:

```
git clone [your fork]
cd project-rainbow
nix develop
```

The game also need a server to work, you can launch a temporary development server using:

```
git clone https://github.com/Mouthless-Stoat/project-rainbow-server.git
cd project-rainbow-server
nix develop
```

This is useful if you want to inspect the network messages to debug stuff especially related to stalling.

#### If you do not have nix

If you don't have `nix` you have to install yourself a few tools manually, you need:

- [Godot 4.6.1](https://godotengine.org/download/archive/4.6.1-stable/), the game engine for Project Rainbow.
- [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit), a tool to format and lint code.
- [git](https://git-scm.com/), a version control system that help with keeping track of changes.
- [deno](https://deno.com/), a JavaScript run time use for the server.

You will need to run the following in a terminal, you can start by cloning the git repo and launch the game like this:

```
git clone [your fork]
cd project-rainbow
git remote add origin [your fork]
godot project.godot
```

After that open a new terminal and run the following to start the server, you would also need port `42069` open on your machine:

```
git clone https://github.com/Mouthless-Stoat/project-rainbow-server.git
cd project-rainbow-server
deno -A main.ts
```

### Contributing

The work flow is implement the feature you want make a commit, implement more and commit lastly to submit a pull request on github with your fork. Below are git basic to help with you contributing

```
git add * # Add all your changes to a commit
git commit -m "Your commit message" # Commit all the changes to a commit with a message
git push -u origin main # you only need to run this once to sync to a main branch after that you can just use `git push`
```

A commit should only contain small feature or addition, imagine you are adding a new sigil for example that require adding new stack action. Add that new stack action then commit, add the sigil then commit again.

### Guideline

If you are adding multiple sigils, make multiple commits for each sigil. If you encounter a bug while doing something unrelated to your feature refrain from fixing it and instead defer it to another pr. Most pr should be self contain, if you can't describe your changes or feature in 1 or 2 sentences it should not be in the same pr and instead should be multiple. The following are examples of good pr title:

- Implements `[new action type]` and `[sigil that require the action]`
  - This is good because is it self contain to a single new action implementation and a sigil that use the action as an example.
- Improve deck editor UI with `[blah blah blah]`
  - This is good because it clearly define which feature it is improving and what the improvement are.
- Implements a new unimplemented sigil
  - This is fine as long as the pr description describe which sigil its implement

In addition to this commit message should also be descriptive to what it is changing. Messages that just say "bunch of fixes" should be avoided, instead opted for "fix bugs where ...", "implement x to y", "add new sigil x", "refactor x to be cleaner", "rename variable to". Those last two example would probably also need a description describing what actually changes and why. Commit that introduce breaking change to public facing API (any thing that does not start with a `_`), or large refactoring pass that require code from multiple part to change should be preface with "BREAKING CHANGE:" so the commit message become "BREAKING CHANGE: introduce x and so deprecated y".

As for coding style here a short list, ill update this as more become relevant:

- Prefer early return if possible
- Prefer casting with `var x := value as _` over `var x: _ = value`
