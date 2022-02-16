<h1 align="center">Menu11</h1>
<p align="center"><i><b>A highly customizable launcher inspired from windows 11 menu. Fork of MenuZ.</b></i></p>
<p align="center">
<a href="https://github.com/prateekmedia/Menu11/releases"><img alt="GitHub release" src="https://img.shields.io/github/v/release/prateekmedia/Menu11"/></a> <a href="LICENSE"><img alt="License" src="https://img.shields.io/github/license/prateekmedia/Menu11?color=blue"/></a> <a href="#installing-manually"><img alt="Install Manually" src="https://img.shields.io/badge/Install Manually-git-blue"/></a>
</p>
<p align="center">
  <img src="https://user-images.githubusercontent.com/41370460/126046490-08a6f26d-ee70-4ba9-b2ce-a9f2e5ad1a59.png" width=400>
</p>

Deprecated:
- It is not maintainable and has many errors and bugs, unfortunately I am not on KDE right now so I cannot help with those
Suggested replacement: https://github.com/adhec/OnzeMenuKDE

OnzeMenu is not that customizable but I hope it will continue to improve.


#### *Special Thanks to*
- [Prateek SU](https://github.com/prateekmedia) / Me for creating [Menu 11](https://github.com/prateekmedia/) by forking [Menu Z](https://store.kde.org/p/1367167/)  and for continuously adding and improving features.
- [Nayam Amarshe](https://github.com/NayamAmarshe) for improving the design.
- [John Vincent](https://github.com/TenSeventy7) for improving grid view of recommended section.
- [Lupert Everett](https://github.com/LupertEverett) for adding multiple footer icons.  
<a href="https://github.com/prateekmedia/Menu11/graphs/contributors"><img alt="Know More" src="https://shields.io/badge/-Know More-blue"/></a>

### Frequently asked questions(FAQ)
#### How do I fix "Sorry! There was an error loading Menu 11."
This is most likely due to missing `plasma-widgets-addons` package on your system.

You can install this using `sudo apt install plasma-widgets-addons` on Ubuntu / Debian Distros or `sudo pacman -S kdeplasma-addons` on Arch based distro.

If you have any other distro then please search for the package name for your distro.

#### The elements look messed up, What's wrong with this applet?
This can be due to various reasons:
- KDE version you are using is too old, we recommend at least **KDE 5.21** if you are using this applet.
- Another applet or program is causing this issue.

You can [create an issue](https://github.com/prateekmedia/Menu11/issues/new) if you think it's due to a KDE update or it's not mentioned above.

<h2 align="center">Installing Manually</h2>

### Using git
```bash
git clone https://github.com/prateekmedia/Menu11.git ~/.local/share/plasma/plasmoids/menu11;
kquitapp5 plasmashell || killall plasmashell && kstart5 plasmashell;
```
