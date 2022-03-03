# install homebrew without sudo
cd /goinfre/akarahan
mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew

# install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# download blex mono
curl https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/IBMPlexMono/Mono/complete/Blex%20Mono%20Nerd%20Font%20Complete%20Mono.ttf --output blexmono.ttf
open blexmono.ttf

# install tmux
brew install tmux
