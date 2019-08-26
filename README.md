# hello-nes

A simple "Hello World" style program for the Nintendo Entertainment System. It demonstrates initializing the NES, drawing a background, reading from controllers, and drawing / controlling a sprite. 

NES development is new to me, so I decided to start with a simple Hello World project. I tried to keep it simple and add plenty of comments. I hope others find it useful.

## Getting Starting

Here's what you need to get started with this code.

### Tools
The code uses the [ca65 macro assembler](https://cc65.github.io/doc/ca65.html) and [ld65 linker](https://cc65.github.io/doc/ld65.html). [Install cc65](https://wiki.nesdev.com/w/index.php/Installing_CC65) to get both tools and include them in your path.

The graphics are contained in CHR files, and I found [YY-CHR.NET](https://wiki.nesdev.com/w/index.php/YY-CHR) useful for editing these files.

For debugging, I like [Mesen](https://www.mesen.ca/). It can import the `hello.nes.dbg` file that is generated at build time to show the code's labels.

### Building
On Windows, just run `build.cmd`. The same commands in that file should work on Linux; I didn't just include a shell script. I probably should add a makefile. In any case, a successful build should produce `hello.nes` - run that in the NES emulator / debugger of your choice.

## Thanks
I didn't figure this out in a vacuum. These people and resources helped me a bunch.
- [Nesdev Wiki](http://wiki.nesdev.com) - A great reference
- [Michael Chiaramonte's YouTube video](https://www.youtube.com/watch?v=4UIBOZzz-1I)
- [This](https://www.masswerk.at/6502/6502_instruction_set.html) and [this](http://www.6502.org/tutorials/6502opcodes.html) 6502 instruction set reference.
- [Brad Smith's NES-ca65-example](https://github.com/bbbradsmith/NES-ca65-example)
- [Damian Yerrick's NES project template](https://pineight.com/nes/#template)

## Author

- **Matthew Justice** [matthewjustice](https://github.com/matthewjustice)


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details




