# Mouse Trap

<br clear="left"/>

A KWin script that uses the built-in screen barrier to keep the cursor confined to the current screen on Wayland.

## What it’s for

There’s no good, reliable way to confine the cursor to the current screen in KDE + Wayland. This is especially troublesome when gaming, when the cursor can escape and the game loses focus. In my case, it causes problems in grand strategy games, where I can’t move the mouse to the edges of the screen. Install this KWin script and press the keyboard shortcut (**Ctrl+Shift+L**) to confine the cursor to the current monitor. Press it again, or disable the extension, to restore the original behavior.

In theory, you can also use gamescope, which is what I used for games like *Cities: Skylines*. However, it has some downsides:

* Gamescope does more than just confine the cursor. In some cases, it can even cause performance regressions.
* Mouse Trap can be disabled in the middle of a game, giving you more flexibility.
* You can toggle Mouse Trap outside of games too, so you may find other uses for it in your day-to-day workflow.

And finally, it’s just a KWin script, so it’s extremely lightweight.

## Install

Go to **System Settings > Window Management > KWin Scripts**, select **Get New...**, and search for *“Mouse Trap”*. It should appear in the official KDE list. You can also download `mouse-trap-[VERSION].kwinscript` from **Releases** and install it via **System Settings > Window Management > KWin Scripts > Install from File...**. Then just enable the script.

Alternatively, run `kpackagetool6 --type=KWin/Script -i mouse-trap-[VERSION].kwinscript` from the directory where you downloaded it. Replace `[VERSION]` with the version shown on the release.

> [!TIP]
> It’s best to install it from the KDE store using "**Get New...**", That way, the script will update automatically along with your system.

## How to use it

1. Move the cursor to the screen where you want to keep it.
2. Press **Ctrl+Shift+L** to confine the mouse to the current monitor.
3. Press **Ctrl+Shift+L** again to release it.

To change the shortcut, open the script’s settings and follow the link to **KDE Shortcuts**. Look for *“Toggle Mouse Trap”* under **KWin**.

## Known issues

* The confinement isn’t **strict**. Very fast movements may let the cursor briefly slip onto another monitor. In practice, though, this doesn’t cause any problems.
* If the cursor body is on one screen while its sprite is on the other, most of the cursor may be rendered on a monitor where it isn’t actually located. This is purely visual, the pointer remains on the confined side. It’s unavoidable, and also happens with cursor limiters on other operating systems.
* I only have two monitors, so it’s only been tested with two! If it works for you with more than two monitors, please let me know.

## Contributing

This is a simple piece of software that was not difficult to carry out. I don’t think there’s much else to do, it does what it’s meant to. Still, there may be bugs I haven’t run into yet. I’m especially concerned about edge cases with more than two monitors.

If you run into a problem, you can open an issue. If we agree there’s a problem, you can also submit a pull request with a potential fix. The use of AI is allowed, but **not** for writing the issue or pull request. And **please** don’t submit anything without having read and understood the code.

## License

This software is distributed under the [MIT License](LICENSE).
